package main 

import "vst3"

import "base:intrinsics"
import "base:runtime"

import "core:encoding/uuid"
import "core:fmt"
import "core:math"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:thread"
import "core:time"
import "core:unicode/utf16"

import xlib "vendor:x11/xlib"

// Example user data:

ExampleUuid :: "1002df00-56d3-4920-a394-1205f69854a6"
ExampleControllerUuid :: "3981d015-fb51-43fb-9deb-03488f84c270"

ExampleUrl :: "www.notgotawebsitem8.com"
ExampleVendor :: "Noice"
ExampleName :: "odin"
ExampleEmail :: "edgallyot@gmail.com"
ExampleVersion :: "0.0.1"
ExampleCategory :: "Audio Module Class"

InputChannelCount :: 2
OutputChannelCount :: 2
MidiInputCount :: 0
MidiOutputCount :: 0

ParameterId :: enum u32 {
    Bypass = 0,
    Gain = 1,
}

ParameterNames := [ParameterId] string {
    .Bypass = "Bypass",
    .Gain = "Gain",
}

ParameterShortNames := [ParameterId] string {
    .Bypass = "Byps",
    .Gain = "Gain",
}

ParameterUnits := [ParameterId] string {
    .Bypass = "",
    .Gain = "dB",
}

ParameterStepCounts := [ParameterId] i32 {
    .Bypass = 1,
    .Gain = 1024,
}

// Parameter Defaults are in their real values, e.g: dB
ParameterDefaults := [ParameterId] f64 {
    .Bypass = 0.0,
    .Gain = -math.F64_MAX,
}

ParameterFlags := [ParameterId] i32 {
    .Bypass = i32(vst3.ParameterFlags.CanAutomate) | i32(vst3.ParameterFlags.IsBypass),
    .Gain = i32(vst3.ParameterFlags.CanAutomate)
}

ParameterInterpolator :: struct {
    current: f64,
    target: f64,
    step: f64,
    count: f64,
}

set_interpolator_target :: proc "contextless" (i: ^ParameterInterpolator, v: f64, fs: f64) -> () {
    interp_ms :: 10
    step_count := (interp_ms * fs) / 1000.0 // 10ms
    if v != i.target {
        i.target = v
        i.count = step_count
        i.step = (i.target - i.current) / f64(step_count)
    }
}

tick_interpolator :: proc "contextless" (i: ^ParameterInterpolator) {
    if i.count > 0 {
        i.count -= 1
        i.current = i.current + i.step
    } else {
        i.count = 0
        i.current = i.target
    }
}

State :: struct {
    c: runtime.Context,
    param_values: [ParameterId]f64,
    interpolators: [ParameterId]ParameterInterpolator,
    sine_phase: f32,
    processing: bool,
    sample_rate: f64,
}

sample_tick :: proc "contextless" (state: ^State, $T: typeid) -> T {
    for p in ParameterId do tick_interpolator(&state.interpolators[p])
    two_pi :T : 2.0 * math.PI
    sine_delta: T = auto_cast (400.0 / state.sample_rate) * two_pi
    state.sine_phase += auto_cast sine_delta
    state.sine_phase = math.mod_f32(state.sine_phase, auto_cast two_pi)
    sample := math.sin(state.sine_phase)
    sample *= f32(state.interpolators[ParameterId.Gain].current)
    sample *= f32(state.interpolators[ParameterId.Bypass].current)
    sample *= 0.1
    return auto_cast sample
}

to_parameter_id :: proc "contextless" (v: $I) -> (ParameterId, vst3.Result) where intrinsics.type_is_integer(I) {
    if v < 0 || v > (len(ParameterId) - 1) {
        return {}, vst3.Result.InvalidArgument
    }
    return auto_cast v, nil
}

normalise_gain :: proc "contextless" (v: f64) -> f64 {
    return math.pow(10, v / 20.0)
}

denormalise_gain :: proc "contextless" (v: f64) -> f64 {
    return 20.0 * math.log(v, 10)
}

normalise_parameter :: proc "contextless" (p: ParameterId, v: f64) -> f64 {
    switch p {
    case .Bypass: return v
    case .Gain: return normalise_gain(v)
    }
    return 0.0
}

denormalise_parameter :: proc "contextless" (p: ParameterId, v: f64) -> f64 {
    switch p {
    case .Bypass: return v
    case .Gain: return denormalise_gain(v)
    }
    return 0.0
}

parameter_string_by_normalised_value :: proc (p: ParameterId, buffer: []byte, normalised: f64) -> string {
    v := denormalise_parameter(p, normalised)
    switch p {
    case .Bypass: 
        if v > 0.5 {
            return "On"
        } else {
            return "Off"
        }
    case .Gain: 
        if normalised >= 1 {
            return "0.0"
        }
        if normalised <= 0 {
            return "-inf"
        }
        result := strconv.append_float(buffer[:], v, 'f', 2, 64)
        result = strings.trim (result, "+")
        return result
    }
    return {}
}

parameter_denormalised_value_by_string :: proc (p: ParameterId, s: string) -> (f64, vst3.Result) {
    switch p {
    case .Bypass:
        if s == "On" {
            return 1, nil
        } else if s == "Off" {
            return 0, nil
        } else {
            return 0, vst3.Result.InvalidArgument
        }
    case .Gain: 
         res, err := strconv.parse_f64(s)
         if err {
             return 0.0, vst3.Result.InvalidArgument 
         } else {
            return res, nil
         }
    }
    return {}, vst3.Result.InvalidArgument
}

channel_count_to_speaker_arrangement :: proc "contextless" (channel_count: u32) -> vst3.SpeakerArrangement {
    // Do we event need to support more
    if channel_count == 1 {
        return vst3.SpeakerArrangement.MonoSpeaker
    }
    if channel_count == 2 {
        return vst3.SpeakerArrangement.StereoSpeaker
    }
    return vst3.SpeakerArrangement.Empty
}

Gui :: struct {
    thread_handle: ^thread.Thread,
    state: GuiState,
}

GuiState :: struct #packed {
    parent: rawptr,
    run, resize: bool,
    width, height: u32,
    display: ^xlib.Display,
    window: xlib.Window,
    screen: i32,
    gc: xlib.GC,
}

gui_thread :: proc (state: ^GuiState) {
    state.display = xlib.OpenDisplay(nil)    
    state.screen = xlib.DefaultScreen(state.display)
    state.window = xlib.CreateSimpleWindow(state.display, auto_cast uintptr(state.parent), 0, 0 , 800, 600, 0, 0, xlib.BlackPixel(state.display, state.screen))
    mask :xlib.EventMask = {.StructureNotify, .KeyPress, .KeyRelease, .ButtonPress, .ButtonRelease}
    xlib.SelectInput(state.display, state.window, mask)
    xlib.MapWindow(state.display, state.window)
    state.gc = xlib.DefaultGC(state.display, state.screen)
    xlib.Flush(state.display)
    for intrinsics.atomic_load(&state.run) {
        resize := intrinsics.atomic_load(&state.resize)
        if resize {
            xlib.MoveResizeWindow(state.display, state.window, 0, 0, state.width, state.height) 
            intrinsics.atomic_store(&state.resize, !resize)
        }
        e: xlib.XEvent 
        for xlib.CheckWindowEvent(state.display, state.window, mask, &e) {
        }
        xlib.ClearWindow(state.display, state.window)
        xlib.Flush(state.display)
        time.accurate_sleep(33300)
    }
    intrinsics.atomic_store(&state.run, true)
}

start_gui :: proc (gui: ^Gui, parent: rawptr) {
    gui.state.parent = parent
    intrinsics.atomic_store(&gui.state.run, true)
    gui.thread_handle = thread.create_and_start_with_poly_data(&gui.state, gui_thread)
}

finish_gui :: proc "contextless" (gui: ^Gui) {
    context = runtime.default_context()
    intrinsics.atomic_store(&gui.state.run, false)
    for !intrinsics.atomic_load(&gui.state.run) do continue
    intrinsics.atomic_store(&gui.state.run, false)
}

resize_gui :: proc "contextless" (gui: ^Gui, width: u32, height: u32) {
    state := &gui.state
    state.width = width
    state.height = height
    if intrinsics.atomic_load(&state.run) {
        intrinsics.atomic_store(&state.resize, true)
        for intrinsics.atomic_load(&state.resize) do continue
    }
}

// COM implmentation
View :: struct {
    iface: vst3.IPlugView,
    using vtbl: vst3.IPlugViewVtbl,
    ref_count: u32,
    gui: Gui,
}

view_query_interface :: proc "c" (this: rawptr, id: [^]u8, obj: ^rawptr) -> vst3.Result {
    context = runtime.default_context()
    f_unknown_id := parse_uuid (vst3.FUnknown_iid) or_return
    i_view_id := parse_uuid (vst3.IPlugView_iid) or_return
    if slice.equal(id[0:16], i_view_id[0:16]) ||
       slice.equal(id[0:16], f_unknown_id[0:16]) {
        obj^ = this
        return vst3.Result.True
    }
    return vst3.Result.NoInterface
}

view_add_ref :: proc "c" (this: rawptr) -> u32 {
    v: ^View = auto_cast this
    v.ref_count += 1
    return v.ref_count
}

view_release :: proc "c" (this: rawptr) -> u32 {
    v: ^View = auto_cast this
    v.ref_count -= 1
    return v.ref_count
}

is_platform_type_supported :: proc "c" (rawptr, cstring) -> vst3.Result {
    return vst3.Result.Ok
}

attached :: proc "c" (this: rawptr, handle: rawptr, type: cstring) -> vst3.Result {
    context = runtime.default_context()
    v: ^View = auto_cast this
    start_gui(&v.gui, handle)
    return vst3.Result.Ok
}

removed :: proc "c" (this: rawptr) -> vst3.Result {
    context = runtime.default_context()
    v: ^View = auto_cast this
    finish_gui(&v.gui)
    return vst3.Result.Ok
}

on_wheel :: proc "c" (rawptr, f32) -> vst3.Result {
    return vst3.Result.Ok
}

on_key_down :: proc "c" (rawptr, u16, i16, i16) -> vst3.Result {
    return vst3.Result.Ok
}

on_key_up :: proc "c" (rawptr, u16, i16, i16) -> vst3.Result {
    return vst3.Result.Ok
}

get_size :: proc "c" (this: rawptr, size: ^vst3.ViewRect) -> vst3.Result {
    return vst3.Result.Ok
}

on_size :: proc "c" (this: rawptr, new_size: ^vst3.ViewRect) -> vst3.Result {
    v: ^View = auto_cast this
    width := u32(new_size.left + new_size.right)
    height := u32(new_size.top + new_size.bottom)
    resize_gui(&v.gui, width, height)
    return vst3.Result.Ok
}

on_focus :: proc "c" (rawptr, u8) -> vst3.Result {
    return vst3.Result.Ok
}

set_frame :: proc "c" (rawptr, ^vst3.IPlugFrame) -> vst3.Result {
    return vst3.Result.Ok
}

can_resize :: proc "c" (rawptr) -> vst3.Result {
    return vst3.Result.Ok
}

check_size_constraint :: proc "c" (rawptr, ^vst3.ViewRect) -> vst3.Result {
    return vst3.Result.Ok
}

init_view :: proc (v: ^View) {
    v.query_interface = view_query_interface
    v.add_ref = view_add_ref
    v.release = view_release
    v.is_platform_type_supported = is_platform_type_supported
    v.attached = attached
    v.removed = removed
    v.on_wheel = on_wheel
    v.on_key_down = on_key_down
    v.on_key_up = on_key_up
    v.get_size = get_size
    v.on_size = on_size
    v.on_focus = on_focus
    v.set_frame = set_frame
    v.can_resize = can_resize
    v.check_size_constraint = check_size_constraint
    v.iface.vtbl = &v.vtbl
}

processor_query_interface :: proc "c" (this: rawptr, id: [^]u8, obj: ^rawptr) -> vst3.Result {
    context = runtime.default_context()
    f_unknown_id := parse_uuid (vst3.FUnknown_iid) or_return
    i_processor_id := parse_uuid (vst3.IAudioProcessor_iid) or_return
    if slice.equal(id[0:16], i_processor_id[0:16]) ||
       slice.equal(id[0:16], f_unknown_id[0:16]) {
        obj^ = this
        return vst3.Result.True
    }
    return vst3.Result.NoInterface
}

processor_add_ref :: proc "c" (this: rawptr) -> u32 {
    p: ^Processor = auto_cast this
    p.ref_count += 1
    return p.ref_count
}

processor_release :: proc "c" (this: rawptr) -> u32 {
    p: ^Processor = auto_cast this
    p.ref_count -= 1
    return p.ref_count
}

set_bus_arrangements :: proc "c" (this: rawptr, inputs: [^]vst3.SpeakerArrangement, num_inputs: i32, outputs: [^]vst3.SpeakerArrangement, num_outputs: i32) -> vst3.Result {
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, processor))
    state := &plugin.state
    context = state.c
    input_ok := true
    for input, i in inputs[0:num_inputs] {
        if i > 0 do break
        accepted_speaker := channel_count_to_speaker_arrangement(InputChannelCount)
        input_ok = input_ok && (input == vst3.SpeakerArrangement.Empty || input == accepted_speaker)
    }

    output_ok := true
    for output, i in outputs[0:num_outputs] {
        if i > 0 do break
        accepted_speaker := channel_count_to_speaker_arrangement(OutputChannelCount)
        output_ok = output_ok && (output == vst3.SpeakerArrangement.Empty || output == accepted_speaker)
    }
    
    if !input_ok || !output_ok do return vst3.Result.False
    return vst3.Result.True
}

get_bus_arrangements :: proc "c" (this: rawptr, bus_direction: vst3.BusDirection, index: i32, speaker: ^vst3.SpeakerArrangement) -> vst3.Result {
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, processor))
    state := &plugin.state
    switch bus_direction {
    case .Input: speaker^ = channel_count_to_speaker_arrangement(InputChannelCount)
    case .Output: speaker^ = channel_count_to_speaker_arrangement(OutputChannelCount)
    }
    return vst3.Result.Ok
}

can_process_sample_size :: proc "c" (rawptr, vst3.SymbolicSampleSize) -> vst3.Result {
    return vst3.Result.Ok
}

get_latency_samples :: proc "c" (rawptr) -> vst3.Result {
    return vst3.Result.Ok
}

setup_processing :: proc "c" (this: rawptr, setup: ^vst3.ProcessSetup) -> vst3.Result {
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, processor))
    state := &plugin.state
    state.sample_rate = setup.sample_rate
    return vst3.Result.Ok
}

set_processing :: proc "c" (this: rawptr, state: u8) -> vst3.Result {
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, processor))
    plugin.state.processing = auto_cast state 
    return vst3.Result.Ok
}


process :: proc "c" (this: rawptr, data: ^vst3.ProcessData) -> vst3.Result #no_bounds_check {
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, processor))
    state := &plugin.state
    num_samples := data.num_samples
    num_inputs := data.num_inputs
    num_outputs := data.num_outputs
    bus_outputs := data.outputs[:num_outputs]

    for p in ParameterId {
        value := normalise_parameter(p, state.param_values[p])
        if p == ParameterId.Bypass do value = 1.0 - value
        set_interpolator_target(&state.interpolators[p], value, state.sample_rate) 
    }

    for bus in bus_outputs {
        num_channels := bus.num_channels
        if data.symbolic_sample_size == .Sample32 {
             channels := bus.buffers_32[:num_channels]
             for &channel, index in channels {
                 if index == 0 {
                     samples := channel[:num_samples]
                     for &sample, index  in samples {
                         sample = sample_tick(state, f32)
                     } 
                 } else {
                     copy_slice(channel[:num_samples], channels[0][:num_samples])
                 }
             }
        } else {
             channels := bus.buffers_64[:num_channels]
             for &channel, index in channels {
                 if index == 0 {
                     samples := channel[:num_samples]
                     for &sample, index  in samples {
                         sample = sample_tick(state, f64)
                     } 
                 } else {
                     copy_slice(channel[:num_samples], channels[0][:num_samples])
                 }
             }
        }
    }
    return vst3.Result.Ok
}

get_tail_samples :: proc "c" (rawptr) -> u32 {
    return 0
}

init_processor :: proc (p: ^Processor) {
    p.query_interface = processor_query_interface
    p.add_ref = processor_add_ref
    p.release = processor_release
    p.set_bus_arrangements = set_bus_arrangements
    p.get_bus_arrangements = get_bus_arrangements
    p.can_process_sample_size = can_process_sample_size
    p.get_latency_samples = get_latency_samples
    p.setup_processing = setup_processing
    p.set_processing = set_processing
    p.process = process
    p.get_tail_samples = get_tail_samples
    p.iface.vtbl = &p.vtbl
}

Processor :: struct #packed  {
    iface: vst3.IAudioProcessor,
    using vtbl: vst3.IAudioProcessorVtbl,
    ref_count: u32,
}

controller_query_interface :: proc "c" (this: rawptr, id: [^]u8, obj: ^rawptr) -> vst3.Result {
    context = runtime.default_context()
    f_unknown_id := parse_uuid (vst3.FUnknown_iid) or_return
    i_controller_id := parse_uuid (vst3.IEditController_iid) or_return
    if slice.equal(id[0:16], i_controller_id[0:16]) ||
       slice.equal(id[0:16], f_unknown_id[0:16]) {
        obj^ = this
        return vst3.Result.True
    }
    return vst3.Result.NoInterface
}

controller_add_ref :: proc "c" (this: rawptr) -> u32 {
    c: ^Controller = auto_cast this
    c.ref_count += 1
    return c.ref_count
}

controller_release :: proc "c" (this: rawptr) -> u32 {
    c: ^Controller = auto_cast this
    c.ref_count -= 1
    return c.ref_count
}

controller_initialize :: proc "c" (rawptr, ^vst3.FUnknown) -> vst3.Result {
    return vst3.Result.Ok
}

controller_terminate :: proc "c" (rawptr) -> vst3.Result {
    return vst3.Result.Ok
}

set_component_state :: proc "c" (rawptr, ^vst3.IBStream) -> vst3.Result {
    return vst3.Result.Ok
}

controller_set_state :: proc "c" (rawptr, ^vst3.IBStream) -> vst3.Result {
    return vst3.Result.Ok
}

controller_get_state :: proc "c" (rawptr, ^vst3.IBStream) -> vst3.Result {
    return vst3.Result.Ok
}

get_parameter_count :: proc "c" (rawptr) -> i32 {
    return len(ParameterId)
}

get_parameter_info :: proc "c" (this: rawptr, index: i32, info: ^vst3.ParameterInfo) -> vst3.Result {
    context = runtime.default_context()
    mem.set(info, 0, size_of(vst3.ParameterInfo))
    id := to_parameter_id(index) or_return
    info^ = {
        id = auto_cast id,
        step_count = ParameterStepCounts[id],
        unit_id = vst3.UnitID.RootUnit,
        default_normalised_value = ParameterDefaults[id],
        flags = ParameterFlags[id]
    }
    utf16.encode_string(info.title[:], ParameterNames[id])
    utf16.encode_string(info.short_title[:], ParameterShortNames[id])
    utf16.encode_string(info.units[:], ParameterUnits[id])
    return vst3.Result.Ok
}

get_parameter_string_by_value :: proc "c" (this: rawptr, id: u32, value: f64, string_out: [^]u16) -> vst3.Result {
    context = runtime.default_context()
    p := to_parameter_id(id) or_return 
    buffer: [128]byte
    result := parameter_string_by_normalised_value(p, buffer[:], value)
    mem.set(string_out, 0, 128)
    utf16.encode_string(string_out[0:len(result)], result)
    return vst3.Result.Ok
}

get_parameter_value_by_string :: proc "c" (this: rawptr, id: u32, value_string: cstring, value_out: ^f64) -> vst3.Result {
    context = runtime.default_context()
    p := to_parameter_id(id) or_return 
    input := string(value_string)
    res := parameter_denormalised_value_by_string(p, input) or_return
    value_out^ = normalise_parameter(p, res)
    return vst3.Result.Ok
}

normalised_param_to_plain :: proc "c" (this: rawptr, id: u32, value: f64) -> f64 {
    p, err := to_parameter_id(id)
    if err != nil do return 0 
    return denormalise_parameter(p, value)
}

plain_param_to_normalised :: proc "c" (this: rawptr, id: u32, value: f64) -> f64 {
    context = runtime.default_context()
    p, err := to_parameter_id(id)
    if err != nil do return 0 
    return normalise_parameter(p, value)
}

get_param_normalised :: proc "c" (this: rawptr, id: u32) -> f64 {
    context = runtime.default_context()
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, controller))
    p, err := to_parameter_id(id)
    if err != nil do return 0 
    return normalise_parameter(p, plugin.state.param_values[p])
}

set_param_normalised :: proc "c" (this: rawptr, id: u32, value: f64) -> vst3.Result {
    context = runtime.default_context()
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, controller))
    p := to_parameter_id(id) or_return
    v := denormalise_parameter(p, value)
    plugin.state.param_values[p] = v 
    return vst3.Result.Ok
}

set_component_handler :: proc "c" (rawptr, ^vst3.IComponentHandler) -> vst3.Result {
    return vst3.Result.NotImplemented
}

create_view :: proc "c" (this: rawptr, name: cstring) -> ^vst3.IPlugView {
    plugin: ^Plugin = auto_cast (cast(uintptr)this - offset_of(Plugin, controller))
    return auto_cast &plugin.controller.view
}

init_controller :: proc (c: ^Controller) {
    c.query_interface = controller_query_interface
    c.add_ref = controller_add_ref
    c.release = controller_release
    c.set_component_state = set_component_state
    c.set_state = controller_set_state
    c.get_state = controller_get_state
    c.get_parameter_count = get_parameter_count
    c.get_parameter_info = get_parameter_info
    c.get_parameter_string_by_value = get_parameter_string_by_value
    c.get_parameter_value_by_string = get_parameter_value_by_string
    c.normalised_param_to_plain = normalised_param_to_plain
    c.plain_param_to_normalised = plain_param_to_normalised
    c.get_param_normalised = get_param_normalised
    c.set_param_normalised = set_param_normalised
    c.set_component_handler = set_component_handler
    c.create_view = create_view
    c.iface.vtbl = &c.vtbl
    init_view(&c.view)
}

Controller :: struct #packed {
    iface: vst3.IEditController,
    using vtbl: vst3.IEditControllerVtbl,
    ref_count: u32,
    view: View,
}

component_add_ref :: proc "c" (this: rawptr) -> u32 {
    c: ^Component = auto_cast this
    c.ref_count += 1
    return c.ref_count
}

component_release :: proc "c" (this: rawptr) -> u32 {
    c: ^Component = auto_cast this
    c.ref_count -= 1
    return c.ref_count
}

component_query_interface :: proc "c" (this: rawptr, id: [^]u8, obj: ^rawptr) -> vst3.Result {
    context = runtime.default_context()

    plugin: ^Plugin = auto_cast this

    f_unknown_id := parse_uuid (vst3.FUnknown_iid) or_return
    i_component_id := parse_uuid (vst3.IComponent_iid) or_return
    if slice.equal(id[0:16], i_component_id[0:16]) ||
       slice.equal(id[0:16], f_unknown_id[0:16]) {
        obj^ = &plugin.component
        return vst3.Result.True
    }

    i_edit_controller_id := parse_uuid (vst3.IEditController_iid) or_return
    if slice.equal(id[0:16], i_edit_controller_id[0:16]) {
        obj^ = &plugin.controller
        return vst3.Result.True
    }

    i_audio_processor_id := parse_uuid (vst3.IAudioProcessor_iid) or_return
    if slice.equal(id[0:16], i_audio_processor_id[0:16]) {
        obj^ = &plugin.processor
        return vst3.Result.True
    }

    return vst3.Result.NoInterface
}

component_initialize :: proc "c" (this: rawptr, obj: ^vst3.FUnknown) -> vst3.Result {
    return vst3.Result.True
}

component_terminate :: proc "c" (this: rawptr) -> vst3.Result {
    return vst3.Result.True
}

get_controller_class_id :: proc "c" (id: rawptr, tuid: [^]u8) -> vst3.Result {
    context = runtime.default_context()
    id := parse_uuid (ExampleControllerUuid) or_return
    copy_slice(tuid[0:16], id[0:16])
    return vst3.Result.Ok
}

set_io_mode :: proc "c" (rawptr, vst3.IoMode) -> vst3.Result {
    // Do we care?
    return vst3.Result.NotImplemented
}

get_bus_count :: proc "c" (this: rawptr, media_type: vst3.MediaType, bus_direction: vst3.BusDirection) -> i32 {
    switch media_type {
    case .Audio: 
        switch bus_direction {
        case .Input: return InputChannelCount
        case .Output: return OutputChannelCount
        }
    case .Event: 
        switch bus_direction {
        case .Input: return MidiInputCount 
        case .Output: return MidiOutputCount 
        }
    }
    return 0
}

get_bus_info :: proc "c" (this: rawptr, media_type: vst3.MediaType, bus_direction: vst3.BusDirection, index: i32, info: ^vst3.BusInfo) -> vst3.Result {
    context = runtime.default_context()

    // Example is going to support main stereo bus, no auxes.
    if index != 0 {
        return vst3.Result.InvalidArgument
    }

    switch media_type {
    case .Audio: 
        switch bus_direction {
        case .Input: 
            info^ = {
                media_type = media_type,
                direction =  bus_direction,
                channel_count = InputChannelCount,
                bus_type =  vst3.BusType.Main,
                flags = vst3.BusFlags.DefaultActive,
            }
            utf16.encode_string(info.name[:], "Audio Input")
        case .Output: 
            info^ = {
                media_type = media_type,
                direction =  bus_direction,
                channel_count = OutputChannelCount,
                bus_type =  vst3.BusType.Main,
                flags = vst3.BusFlags.DefaultActive,
            }
            utf16.encode_string(info.name[:], "Audio Output")
        }
    case .Event: 
        switch bus_direction {
        case .Input: 
            info^ = {
                media_type = media_type,
                direction =  bus_direction,
                channel_count = MidiInputCount,
                bus_type =  vst3.BusType.Main,
                flags = vst3.BusFlags.DefaultActive,
            }
            utf16.encode_string(info.name[:], "MIDI Input")
        case .Output: 
            info^ = {
                media_type = media_type,
                direction =  bus_direction,
                channel_count = MidiOutputCount,
                bus_type =  vst3.BusType.Main,
                flags = vst3.BusFlags.DefaultActive,
            }
            utf16.encode_string(info.name[:], "MIDI Output")
        }
    }
    return vst3.Result.Ok
}

get_routing_info :: proc "c" (rawptr, ^vst3.RoutingInfo, ^vst3.RoutingInfo) -> vst3.Result {
    // Do we care?
    return vst3.Result.NotImplemented
}

activate_bus :: proc "c" (rawptr, vst3.MediaType, vst3.BusDirection, i32, u8) -> vst3.Result {
    // Do we care?
    return vst3.Result.Ok
}

set_active :: proc "c" (rawptr, u8) -> vst3.Result {
    // Do we care?
    return vst3.Result.Ok
}

component_set_state :: proc "c" (rawptr, ^vst3.IBStream) -> vst3.Result {
    return vst3.Result.NotImplemented
}

component_get_state :: proc "c" (rawptr, ^vst3.IBStream) -> vst3.Result {
    return vst3.Result.NotImplemented
}

init_component :: proc (c: ^Component) {
    c.query_interface = component_query_interface
    c.add_ref = component_add_ref
    c.release = component_release
    c.initialize = component_initialize
    c.terminate = component_terminate 
    c.get_controller_class_id = get_controller_class_id
    c.set_io_mode = set_io_mode
    c.get_bus_count = get_bus_count
    c.get_bus_info = get_bus_info
    c.get_routing_info = get_routing_info
    c.activate_bus = activate_bus
    c.set_active = set_active
    c.set_state = component_set_state
    c.get_state = component_get_state
    c.iface.vtbl = &c.vtbl
}

Component :: struct #packed {
    iface: vst3.IComponent,
    using vtbl: vst3.IComponentVtbl,
    ref_count: u32,
}

make_plugin :: proc () -> ^Plugin {
    p := new (Plugin)
    c := &p.component
    init_component(c)
    ctrl := &p.controller
    init_controller(ctrl)
    processor := &p.processor
    init_processor (processor)
    p.state.param_values = ParameterDefaults
    return p
}

Plugin :: struct #packed {
    component: Component,
    controller: Controller,
    processor: Processor,
    state: State,
}

parse_uuid :: proc (id: string) -> (uuid.Identifier, vst3.Result) {
    factory_id, err :=  uuid.read (id) 
    if err != nil {
        return {}, vst3.Result.False
    }
    return factory_id, nil
}

factory_query_interface :: proc "c" (this: rawptr, id: [^]u8, obj: ^rawptr) -> vst3.Result {
    context = runtime.default_context()

    f_unknown_id := parse_uuid(vst3.FUnknown_iid) or_return
    factory_id := parse_uuid(vst3.IPluginFactory_iid) or_return
    factory_2_id := parse_uuid(vst3.IPluginFactory2_iid) or_return
    factory_3_id := parse_uuid(vst3.IPluginFactory3_iid) or_return

    if slice.equal(id[0:16], factory_id[:]) ||
       slice.equal(id[0:16], factory_2_id[:]) ||
       slice.equal(id[0:16], factory_3_id[:]) ||
       slice.equal(id[0:16], f_unknown_id[:]) {
        obj^ = this
        return vst3.Result.True
    }

    return vst3.Result.NoInterface
}

factory_add_ref :: proc "c" (this: rawptr) -> u32 {
    f: ^Factory = auto_cast this
    f.ref_count += 1
    return f.ref_count
}

factory_release :: proc "c" (this: rawptr) -> u32 {
    f: ^Factory = auto_cast this
    f.ref_count -= 1
    return f.ref_count
}

get_factory_info :: proc "c" (this: rawptr, info: ^vst3.PFactoryInfo) ->  vst3.Result {
    copy(info.url[0 : 256], ExampleUrl)
    copy(info.email[0 : 128], ExampleEmail)
    copy(info.vendor[0 : 64], ExampleVendor)
    info.flags = vst3.kDefaultFactoryFlags
    return vst3.Result.Ok
}

count_classes :: proc "c" (this: rawptr) -> i32 {
    return 1
}

get_class_info :: proc "c" (this: rawptr, idx: i32, info: ^vst3.PClassInfo) -> vst3.Result {
    context = runtime.default_context()
    example_id := parse_uuid(ExampleUuid) or_return
    mem.set(info, 0, size_of(vst3.PClassInfo))
    copy_slice(info.cid[0:16], example_id[0:16])
    copy_from_string(info.name[0 : 64], ExampleName)
    copy_from_string(info.category[0 : 32], ExampleCategory)
    info.cardinality = cast(i32)vst3.Cardinality.ManyInstances
    return vst3.Result.Ok
}

create_instance :: proc "c" (this: rawptr, class_id: [^]u8, interface_id: [^]u8, obj: ^rawptr) -> vst3.Result {
    context = runtime.default_context()
    example_id := parse_uuid(ExampleUuid) or_return
    if slice.equal(example_id[0:16], class_id[0:16]) {
        f_unknown_id := parse_uuid (vst3.FUnknown_iid) or_return
        i_component_id := parse_uuid (vst3.IComponent_iid) or_return

        if slice.equal(f_unknown_id[:], interface_id[0:16]) || slice.equal(i_component_id[:], interface_id[0:16]) {
            plugin := make_plugin()
            plugin.state.c = context
            obj^ = auto_cast &plugin.component
            return vst3.Result.True
        }
    }

    return vst3.Result.NoInterface
}

get_class_info_2 :: proc "c" (this: rawptr, index: i32, info: ^vst3.PClassInfo2) -> vst3.Result {
    context = runtime.default_context()
    mem.set(info, 0, size_of(vst3.PClassInfo2))
    example_id := parse_uuid(ExampleUuid) or_return
    copy_slice(info.cid[:], example_id[:])
    info.cardinality = cast(i32)vst3.Cardinality.ManyInstances
    copy_from_string(info.name[:], ExampleName)
    copy_from_string(info.category[:], ExampleCategory)
    info.class_flags = cast(u32)vst3.ComponentFlags.SimpleModeSupported
    copy_from_string(info.sub_categories[:], vst3.kInstrument)
    copy_from_string(info.vendor[:], ExampleVendor)
    copy_from_string(info.version[:], ExampleVersion)
    copy_from_string(info.sdk_version[:], vst3.SDKVersionString)
    return vst3.Result.Ok
}

get_class_info_unicode :: proc "c" (this: rawptr, index: i32, info: ^vst3.PClassInfoW) -> vst3.Result {
    context = runtime.default_context()
    mem.set(info, 0, size_of(vst3.PClassInfoW))
    example_id := parse_uuid(ExampleUuid) or_return
    copy_slice(info.cid[:], example_id[:])
    info.cardinality = cast(i32)vst3.Cardinality.ManyInstances
    utf16.encode_string(info.name[:], ExampleName)
    copy_from_string(info.category[:], ExampleCategory)
    info.class_flags = cast(u32)vst3.ComponentFlags.SimpleModeSupported
    copy_from_string(info.sub_categories[:], vst3.kInstrument)
    utf16.encode_string(info.vendor[:], ExampleVendor) 
    utf16.encode_string(info.version[:], ExampleVersion)
    utf16.encode_string(info.sdk_version[:], vst3.SDKVersionString)
    return vst3.Result.Ok
}

set_host_context :: proc "c" (this: rawptr, ctx: ^vst3.FUnknown) -> vst3.Result {
    return vst3.Result.Ok
}

Factory :: struct #packed {
    iface: vst3.IPluginFactory3,
    using vtbl: vst3.IPluginFactory3Vtbl,
    ref_count : u32,
}

x: ^Factory

@export ModuleEntry :: proc "c" () -> bool {
    return true
}

@export ModuleExit :: proc "c" () -> bool {
    return true
}

@export GetPluginFactory :: proc "c" () -> ^vst3.IPluginFactory3 {
    context = runtime.default_context()
    if x == nil {
        x = new(Factory)
        x.query_interface = factory_query_interface
        x.add_ref = factory_add_ref 
        x.release = factory_release 
        x.get_factory_info = get_factory_info 
        x.count_classes = count_classes
        x.get_class_info = get_class_info 
        x.create_instance = create_instance 
        x.get_class_info_2 = get_class_info_2 
        x.get_class_info_unicode = get_class_info_unicode
        x.set_host_context = set_host_context
        x.iface.vtbl = &x.vtbl
    } else {
        x.add_ref(auto_cast x)
    }
    return auto_cast x
}
