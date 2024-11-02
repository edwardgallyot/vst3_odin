package main 

import "core:mem"
import "base:runtime"
import "core:os"
import "vst3"
import "base:intrinsics"
import "core:encoding/uuid"
import "core:strings"
import "core:unicode/utf16"
import "core:slice"

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
    .Gain = "lin",
}

ParameterStepCounts := [ParameterId] i32 {
    .Bypass = 1,
    .Gain = 1024,
}

ParameterDefaults := [ParameterId] f64 {
    .Bypass = 0.0,
    .Gain = 1.0,
}

ParameterFlags := [ParameterId] i32 {
    .Bypass = i32(vst3.ParameterFlags.CanAutomate) | i32(vst3.ParameterFlags.IsBypass),
    .Gain = i32(vst3.ParameterFlags.CanAutomate)
}

to_parameter_id :: proc (v: $I) -> (ParameterId, vst3.Result) where intrinsics.type_is_integer(I) {
    if v < 0 || v > (len(ParameterId) - 1) {
        return {}, vst3.Result.InvalidArgument
    }
    return auto_cast v, nil
}

normalise_gain :: proc (v: f64) -> f64 {
    return v
}

denormalise_gain :: proc (v: f64) -> f64 {
    return v
}

normalise_parameter :: proc (p: ParameterId, v: f64) -> f64 {
    switch p {
    case .Bypass: return v
    case .Gain: return normalise_gain(v)
    }
    return 0.0
}

denormalise_parameter :: proc (p: ParameterId, v: f64) -> f64 {
    switch p {
    case .Bypass: return v
    case .Gain: return denormalise_gain(v)
    }
    return 0.0
}

channel_count_to_speaker_arrangement :: proc (channel_count: u32) -> vst3.SpeakerArrangement {
    // Do we event need to support more
    if channel_count == 1 {
        return vst3.SpeakerArrangement.MonoSpeaker
    }
    if channel_count == 2 {
        return vst3.SpeakerArrangement.StereoSpeaker
    }
    return vst3.SpeakerArrangement.Empty
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
    context = runtime.default_context()
    input_ok := true
    for input, i in inputs[0:num_inputs] {
        if i > 0 {
            break
        }
        accepted_speaker := channel_count_to_speaker_arrangement(InputChannelCount)
        input_ok = input_ok && (input == vst3.SpeakerArrangement.Empty || input == accepted_speaker)
    }

    output_ok := true
    for output, i in outputs[0:num_outputs] {
        if i > 0 {
            break
        }
        accepted_speaker := channel_count_to_speaker_arrangement(OutputChannelCount)
        output_ok = output_ok && (output == vst3.SpeakerArrangement.Empty || output == accepted_speaker)
    }
    
    if input_ok && output_ok {
        return vst3.Result.True
    } else {
        return vst3.Result.False
    }
}

get_bus_arrangements :: proc "c" (this: rawptr, bus_direction: vst3.BusDirection, index: i32, speaker: ^vst3.SpeakerArrangement) -> vst3.Result {
    context = runtime.default_context()
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

setup_processing :: proc "c" (rawptr, ^vst3.ProcessSetup) -> vst3.Result {
    return vst3.Result.Ok
}

set_processing :: proc "c" (rawptr, u8) -> vst3.Result {
    return vst3.Result.Ok
}

process :: proc "c" (rawptr, ^vst3.ProcessData) -> vst3.Result {
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

get_parameter_string_by_value :: proc "c" (rawptr, u32, f64, vst3.String128) -> vst3.Result {
    return vst3.Result.Ok
}

get_parameter_value_by_string :: proc "c" (rawptr, u32, cstring, ^f64) -> vst3.Result {
    return vst3.Result.Ok
}

normalised_param_to_plain :: proc "c" (rawptr, u32, f64) -> f64 {
    return 0
}

plain_param_to_normalised :: proc "c" (rawptr, u32, f64) -> f64 {
    return 0
}

get_param_normalised :: proc "c" (this: rawptr, id: u32) -> f64 {

    return 0
}

set_param_normalised :: proc "c" (rawptr, u32, f64) -> vst3.Result {
    return vst3.Result.Ok
}

set_component_handler :: proc "c" (rawptr, ^vst3.IComponentHandler) -> vst3.Result {
    return vst3.Result.NotImplemented
}

create_view :: proc "c" (rawptr, cstring) -> ^vst3.IPlugView {
    return nil
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
}

Controller :: struct #packed {
    iface: vst3.IEditController,
    using vtbl: vst3.IEditControllerVtbl,
    ref_count: u32,
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
        obj^ = auto_cast &plugin.component
        return vst3.Result.True
    }

    i_edit_controller_id := parse_uuid (vst3.IEditController_iid) or_return
    if slice.equal(id[0:16], i_edit_controller_id[0:16]) {
        obj^ = auto_cast &plugin.controller
        return vst3.Result.True
    }

    i_audio_processor_id := parse_uuid (vst3.IAudioProcessor_iid) or_return
    if slice.equal(id[0:16], i_audio_processor_id[0:16]) {
        obj^ = auto_cast &plugin.processor
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
    return p
}

Plugin :: struct #packed {
    component: Component,
    controller: Controller,
    processor: Processor,
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
        iid := interface_id[0:16]
        f_unknown_id := parse_uuid (vst3.FUnknown_iid) or_return
        i_component_id := parse_uuid (vst3.IComponent_iid) or_return

        if slice.equal(f_unknown_id[:], iid) || slice.equal(i_component_id[:], iid) {
            plugin := make_plugin()
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

@thread_local x: ^Factory

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
