package tone_generator

import vst3 "../../vst3"
import glx "../../glx"

import "base:intrinsics"
import "base:runtime"

import "core:c"
import "core:encoding/uuid"
import "core:fmt"
import "core:image/png"
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
import gl "vendor:OpenGL"
import tt "vendor:stb/truetype"

// TODO(edg): Deallocating memory.
// TODO(edg): LOGGG!!!!

// Example user data:

ExampleUuid :: "1002df00-56d3-4920-a394-1205f69854a6"
ExampleControllerUuid :: "3981d015-fb51-43fb-9deb-03488f84c270"

ExampleUrl :: "www.notgotawebsitem8.com"
ExampleVendor :: "Noice"
ExampleName :: "tone_generator"
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

// Adapted from https://github.com/rigtorp/SPSCQueue/blob/master/include/rigtorp/SPSCQueue.h
ParameterUpdateSpscQueueSize :: 16
ParameterUpdateSpscQueue :: struct {
    read: uint,
    read_cache: uint,
    write: uint,
    write_cache: uint,
    buffer: [ParameterUpdateSpscQueueSize]f64,
}

push_parameter_update :: proc "contextless" (queue: ^ParameterUpdateSpscQueue, value: f64) -> bool {
    write := intrinsics.atomic_load_explicit(&queue.write, .Relaxed)
    next_write := write + 1
    if next_write == ParameterUpdateSpscQueueSize do next_write = 0 
    if next_write == queue.read_cache {
        queue.read_cache = intrinsics.atomic_load_explicit(&queue.read, .Acquire)
        if next_write == queue.read_cache do return false
    }
    queue.buffer[write] = value
    intrinsics.atomic_store_explicit(&queue.write, next_write, .Release)
    return true
}

pop_parameter_update :: proc "contextless" (queue: ^ParameterUpdateSpscQueue) -> (f64, bool) {
    read := intrinsics.atomic_load_explicit(&queue.read, .Relaxed)
    if read == queue.write_cache {
        queue.write_cache = intrinsics.atomic_load_explicit(&queue.write, .Acquire)
        if queue.write_cache == read do return {}, false
    }
    res := queue.buffer[read]
    next_read := read + 1
    if next_read == ParameterUpdateSpscQueueSize do next_read = 0
    intrinsics.atomic_store_explicit(&queue.read, next_read, .Release)
    return res, true
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
    gui_active: bool,
    audio_to_gui, 
    gui_to_audio, 
    controller_to_audio: [ParameterId]ParameterUpdateSpscQueue,
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
    sample *= f32(state.interpolators[.Gain].current)
    sample *= f32(state.interpolators[.Bypass].current)
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
    denormalised := denormalise_parameter(p, normalised)
    switch p {
    case .Bypass: 
        if denormalised > 0.5 {
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
        result := strconv.append_float(buffer[:], denormalised, 'f', 2, 64)
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

v3 :: [3]f32

GuiInitialWidth :: 400
GuiInitialHeight :: 400

Gui :: struct {
    thread_handle: ^thread.Thread,
    state: GuiState,
}

GuiState :: struct #packed {
    parent: rawptr,
    run, resize: bool,
    audio_to_gui, gui_to_audio: ^[ParameterId]ParameterUpdateSpscQueue,
    width, height: u32,
    display: ^xlib.Display,
    window: xlib.Window,
    buffer: [dynamic]u32,
    screen: i32,
    gc: xlib.GC,
    param_cache: [ParameterId]f64,
}

compile_shader_from_file :: proc ($file: string, shader_type: u32) -> (u32, bool) {
    status: i32
    shader := gl.CreateShader(shader_type)
    src := cstring(#load(file))
    gl.ShaderSource(shader, 1, &src, nil)
    gl.CompileShader(shader)

    if gl.GetShaderiv(shader, gl.COMPILE_STATUS, &status); status != 1 {
        buffer: [512]u8
        gl.GetShaderInfoLog(shader, 512, nil, raw_data(buffer[:]))
        error := cstring(raw_data(buffer[:]))
        fmt.println("error loading", file, ":", error)
        return {}, false 
    }
    return shader, true 
}

destroy_glx_context :: proc (parent: rawptr, window: ^xlib.Window, display: ^^xlib.Display, screen: ^xlib.Screen) {
    xlib.DestroyWindow(display^, window^)
    xlib.CloseDisplay(display^)
    display^ = nil
}

xlib_event_mask :: xlib.EventMask { .StructureNotify, .KeyPress, .KeyRelease, .ButtonPress, .ButtonRelease }

create_glx_context :: proc (parent: rawptr) -> (^xlib.Display, xlib.Window, bool) {
    display := xlib.OpenDisplay(nil)
    screen := xlib.DefaultScreen(display)
    major, minor: i32
    res := glx.QueryVersion(display, &major, &minor)
    if (!res) || (major == 1 && minor < 3) || (major < 1) do return {}, {}, false
    fb_count: i32
    @static visual_attribs := []i32 {
        glx.X_RENDERABLE, 1,
        glx.DRAWABLE_TYPE, glx.WINDOW_BIT,
        glx.RENDER_TYPE, glx.RGBA_BIT,
        glx.X_VISUAL_TYPE, glx.TRUE_COLOR,
        glx.RED_SIZE, 8,
        glx.GREEN_SIZE, 8,
        glx.BLUE_SIZE, 8,
        glx.ALPHA_SIZE, 8,
        glx.DEPTH_SIZE, 24,
        glx.STENCIL_SIZE, 8,
        glx.DOUBLEBUFFER, 1,
        glx.NONE
    }
    // try our ideal attribs
    fb_config := glx.ChooseFBConfig(display, screen, raw_data(visual_attribs), &fb_count) 
    // try any attribs 
    if fb_config == nil do fb_config = glx.ChooseFBConfig(display, screen, nil, &fb_count)
    // TODO(edg): Log critical for the ui thread??
    if fb_config == nil do return {}, {}, false
    best_fbc, worst_fbc, best_num_samp, worst_num_samp := i32(-1), i32(-1), i32(-1), i32(999)
    for c, i in fb_config[:fb_count] {
        visual_info :^xlib.XVisualInfo = glx.GetVisualFromFBConfig(display, c)
        if visual_info == nil do continue
        defer xlib.Free(visual_info)
        samp_buf, samples: i32 = 0, 0
        glx.GetFBConfigAttrib(display, c, glx.SAMPLE_BUFFERS, &samp_buf)
        glx.GetFBConfigAttrib(display, c, glx.SAMPLES, &samples)
        if (best_fbc < 0) || (samp_buf != 0) && (samples > best_num_samp) do best_fbc, best_num_samp = i32(i), samples
        if (worst_fbc < 0) || (samp_buf == 0) || (samples < worst_num_samp) do worst_fbc, worst_num_samp = i32(i), samples
    }
    best_config := fb_config[best_fbc]
    xlib.Free(fb_config)

    visual_info := glx.GetVisualFromFBConfig(display, best_config)
    colormap := xlib.CreateColormap(display, auto_cast uintptr(parent), visual_info.visual, .AllocNone)
    window_attributes := xlib.XSetWindowAttributes {
        background_pixmap = glx.NONE,
        background_pixel = 0,
        border_pixel = 0,
        event_mask = xlib_event_mask,
        colormap = colormap,
    }
    window_attributes_mask := xlib.WindowAttributeMask {.CWBorderPixel, .CWColormap, .CWEventMask, .CWBackPixel }
    window := xlib.CreateWindow(
        display,
        auto_cast uintptr(parent),
        0, 0, GuiInitialWidth, GuiInitialHeight, 
        0,
        visual_info.depth,
        .InputOutput,
        visual_info.visual,
        window_attributes_mask,
        &window_attributes
    )
    xlib.MapWindow(display, window)
    xlib.SelectInput(display, window, xlib_event_mask)
    glx_extensions := glx.QueryExtensionsString(display, screen)
    glXCreateContextAttribsARBProc :: proc "c" (^xlib.Display, glx.FBConfig, glx.Context, c.bool, [^]i32) -> glx.Context
    glXCreateContextAttribsARB := glXCreateContextAttribsARBProc(glx.GetProcAddressARB("glXCreateContextAttribsARB"))
    ctx: glx.Context = nil
    if !strings.contains(string(glx_extensions), "GLX_ARB_create_context") || glXCreateContextAttribsARB == nil {
        ctx = glx.CreateContext(display, visual_info, nil, true)
    } else {
        ctx = glXCreateContextAttribsARB(display, best_config, nil, true, nil)
    }
    defer glx.DestroyContext(display, ctx)
    gl_set_proc_address :: proc (p: rawptr, name: cstring) {
        (cast(^rawptr)p)^ = rawptr(glx.GetProcAddress(name))
    }
    gl.load_up_to(3, 3, gl_set_proc_address)
    if !glx.MakeCurrent(display, auto_cast window, ctx ) do return {}, {}, false

    xlib.Sync(display)
    version := gl.GetString(gl.VERSION)
    fmt.println("loaded gl context with", version)
    return display, window, true
}

// NOTE(edg): yoinked from:
// https://github.com/bg-thompson/OpenGL-Tutorials-In-Odin/blob/main/Wavy-Words/wavy-words.odin#L44
// Information needed to render a single letter.
CharacterTexture :: struct {
    texID   : u32,
    width   : i32, 
    height  : i32,
    bbox_x  : f32,
    bbox_y  : f32,
    advance : f32,
    bitmap  : [^] byte,
}

render_string :: proc (s: string, texture_map: ^map[rune]CharacterTexture,  xpos , ypos : f32, vao : u32, colour: v3) {
    x := xpos
    for r in s {
        x += render_character(r, texture_map, x, ypos, vao, colour)
    }
}

render_character :: proc(r : rune, texture_map: ^map[rune]CharacterTexture,  xpos , ypos : f32, vao : u32, colour: v3) -> (advance : f32) {
    char_texture := texture_map[r]
    w := f32(char_texture.width)
    h := f32(char_texture.height)
    x := xpos + char_texture.bbox_x
    y := ypos + char_texture.bbox_y
    
    character_vertices : [7 * 6] f32 = {
        // Position ; Texture Coords
        x    , y + h,  0, 0, colour.r, colour.g, colour.b,
        x    , y    ,  0, 1, colour.r, colour.g, colour.b,
        x + w, y    ,  1, 1, colour.r, colour.g, colour.b,
        x    , y + h,  0, 0, colour.r, colour.g, colour.b,
        x + w, y    ,  1, 1, colour.r, colour.g, colour.b,
        x + w, y + h,  1, 0, colour.r, colour.g, colour.b,
    }

    gl.BindVertexArray(vao)
    gl.BindTexture(gl.TEXTURE_2D, char_texture.texID)
    gl.BufferSubData(gl.ARRAY_BUFFER,               // update vertices
                     0,                             // offset
                     size_of(character_vertices),   // size
                     &character_vertices)           // data
    // Draw the character!
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    // gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)
    advance = char_texture.advance
    return
}

load_shader_program :: proc ($vert: string, $frag: string) -> (u32, bool) {
    vertex_shader, vertex_ok  := compile_shader_from_file(vert, gl.VERTEX_SHADER)
    if !vertex_ok do return {}, false
    fragment_shader, fragment_ok  := compile_shader_from_file(frag, gl.FRAGMENT_SHADER)
    if !fragment_ok do return {}, false
    shader_program := gl.CreateProgram()
    gl.AttachShader(shader_program, vertex_shader)
    gl.AttachShader(shader_program, fragment_shader)
    gl.LinkProgram(shader_program)
    gl.BindFragDataLocation(shader_program, 0, "out_colour")
    gl.UseProgram(shader_program)
    return shader_program, true
}

string_width_in_pixels :: proc(s: string, texture_map: ^map[rune]CharacterTexture) -> (res: f32) {
    res = 0
    for r in s {
        res += texture_map[r].advance
    }
    return
}

gui_thread :: proc (state: ^GuiState) {
    context = runtime.default_context()

    display, window, ok := create_glx_context(state.parent)
    if !ok {
        fmt.println("failed to create glx context")
        return
    }

    // create the shader program
    image_shader_program, image_shader_err := load_shader_program("shaders/image_vertex.glsl", "shaders/image_fragment.glsl")
    if !image_shader_err do return
    
    state.display, state.window = display, window    
    // image loading 
    image_vao : u32     
    gl.GenVertexArrays(1, &image_vao)
    gl.BindVertexArray(image_vao)

    image_vbo : u32
    gl.GenBuffers(1, &image_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, image_vbo)

    image, err := png.load_from_bytes(#load("asset.png"))

    if err != nil do return
    defer png.destroy(image)

    image_texture := u32(0)
    gl.GenTextures(1, &image_texture)
    gl.BindTexture(gl.TEXTURE_2D, image_texture)
    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(image.width), i32(image.height), 0, gl.RGBA, gl.UNSIGNED_BYTE, raw_data(image.pixels.buf[:]))

    texture_border_colour := []f32{ 0, 0, 0, 0 }
    gl.TexParameterfv(gl.TEXTURE_2D, gl.TEXTURE_BORDER_COLOR, raw_data(texture_border_colour))

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    image_vertices := []f32 {
        //Position  Color               Texcoords
        -0.5,  0.5, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, // Top-left
         0.5,  0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, // Top-right
         0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, // Bottom-right
        -0.5, -0.5, 1.0, 1.0, 1.0, 1.0, 0.0, 1.0  // Bottom-left
    };

    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(image_vertices), raw_data(image_vertices[:]), gl.STATIC_DRAW)

    position_attribute := gl.GetAttribLocation(image_shader_program, "position")
    gl.VertexAttribPointer(auto_cast position_attribute, 2, gl.FLOAT, false, size_of(f32) * 8, 0)
    gl.EnableVertexAttribArray(auto_cast position_attribute)

    colour_attribute := gl.GetAttribLocation(image_shader_program, "in_colour")
    gl.VertexAttribPointer(auto_cast colour_attribute, 4, gl.FLOAT, false, size_of(f32) * 8, 2 * size_of(f32))
    gl.EnableVertexAttribArray(auto_cast colour_attribute)

    texture_attribute := gl.GetAttribLocation(image_shader_program, "in_texture_coordinate")
    gl.VertexAttribPointer(auto_cast texture_attribute, 2, gl.FLOAT, false, size_of(f32) * 8, 6 * size_of(f32))
    gl.EnableVertexAttribArray(auto_cast texture_attribute)

    ebo := u32(0)
    indicies := []u32 { 0, 1, 2, 2, 3, 0 }
    gl.GenBuffers(1, &ebo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, ebo)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, size_of(u32) * len(indicies), raw_data(indicies), gl.STATIC_DRAW)

    // font loading
    // NOTE(edg): We probably wouldn't do something so inefficient in reality
    // but for the sake of simplicity we just load on each gui instantiation.
    font_vao : u32
    gl.GenVertexArrays(1, &font_vao)
    gl.BindVertexArray(font_vao)

    font_shader_program, font_shader_err := load_shader_program("shaders/font_vertex.glsl", "shaders/font_fragment.glsl")
    if !font_shader_err do return

    ttf_bytes := #load("JetBrainsMonoNL-Regular.ttf")
    font : tt.fontinfo
    tt.InitFont(&font, raw_data(ttf_bytes), 0)

    gl.PixelStorei(gl.UNPACK_ALIGNMENT, 1)
    font_maps := make(map[rune]CharacterTexture)
    character_scale := tt.ScaleForPixelHeight(&font, 50)
    for c in 32..=126 {
        index := tt.FindGlyphIndex(&font, rune(c))
        x, y, w, h : i32
        bitmap := tt.GetGlyphBitmap(
            &font,
            0,
            character_scale,
            index,
            &w, &h, &x, &y
        )
        b1, b2, b3, b4 : i32
        tt.GetGlyphBox(&font, index, &b1, &b2, &b3, &b4)

        raw_advance, raw_bearing : i32
        tt.GetGlyphHMetrics(&font, index, &raw_advance, &raw_bearing)
        
        box_x := character_scale * f32(b1);
        box_y := character_scale * f32(b2);
        advance := character_scale * f32(raw_advance)
        bearing := character_scale * f32(raw_bearing)

        texture_id : u32
        gl.GenTextures(1, &texture_id)
        gl.BindTexture(gl.TEXTURE_2D, texture_id)
        gl.TexImage2D(
            gl.TEXTURE_2D,
            0, 
            gl.RED,
            w,
            h,
            0,
            gl.RED,
            gl.UNSIGNED_BYTE,
            bitmap
        )
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR)
        gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

        ct := CharacterTexture { texture_id, w, h, box_x, box_y, advance, bitmap }
        font_maps[rune(c)] = ct
    }

    // NOTE(edg): Bitmaps need freeing
    font_vbo : u32
    gl.GenBuffers(1, &font_vbo)
    gl.BindBuffer(gl.ARRAY_BUFFER, font_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * 7 * 6, nil, gl.DYNAMIC_DRAW)

    // Position / texture position attributes. Don't forget to enable!
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 7 * size_of(f32), 0 * size_of(f32))
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 7 * size_of(f32), 2 * size_of(f32))
    gl.VertexAttribPointer(2, 3, gl.FLOAT, gl.FALSE, 7 * size_of(f32), 4 * size_of(f32))
    gl.EnableVertexAttribArray(0)
    gl.EnableVertexAttribArray(1)
    gl.EnableVertexAttribArray(2)

    proj_mat := [4] f32 {
        1/f32(GuiInitialWidth), 0,
        0, 1/f32(GuiInitialHeight),
    }
    gl.UniformMatrix2fv(gl.GetUniformLocation(font_shader_program, "projection"), 1, gl.TRUE, raw_data(proj_mat[:]))
    gl.Viewport(0, 0, i32(GuiInitialWidth), i32(GuiInitialHeight))

    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

    // main loop
    for intrinsics.atomic_load(&state.run) {
        // get audio thread updates
        start := time.now()
        for p in ParameterId do for {
            v := pop_parameter_update(&state.audio_to_gui[p]) or_break
            state.param_cache[p] = v
        }

        // handle resize
        resize := intrinsics.atomic_load(&state.resize)
        if resize {
            width := state.width
            height := state.height
            intrinsics.atomic_store(&state.resize, !resize)
            gl.Viewport(0, 0, i32(width), i32(height))
            xlib.MoveResizeWindow(state.display, state.window, 0, 0, width, height) 
            xlib.Sync(state.display)
        }

        // handle events
        e := xlib.XEvent{}
        for xlib.CheckWindowEvent(state.display, state.window, xlib_event_mask, &e) {
            #partial switch e.type {
            case .ButtonPress:
                current_bypass := state.param_cache[.Bypass]
                state.param_cache[.Bypass] = 0.0 if current_bypass > 0.5 else 1.0
                push_parameter_update(&state.gui_to_audio[.Bypass], state.param_cache[.Bypass])
            }
        }

        // draw
        white :: v3{255, 255, 255}
        dark_blue := v3 {24, 1, 97}  / white
        red := v3 {235, 54, 120}  / white

        font_colour : v3

        bypass := state.param_cache[.Bypass] > 0.5

        if bypass {
            gl.ClearColor( dark_blue.r, dark_blue.g, dark_blue.b, 0 )
            font_colour = red
        } else {
            gl.ClearColor( red.r, red.g, red.b, 0 )
            font_colour = dark_blue
        }

        gl.UseProgram(image_shader_program)
        gl.Clear(gl.COLOR_BUFFER_BIT)
        gl.BindVertexArray(image_vao)
        gl.BindTexture(gl.TEXTURE_2D, image_texture)
        gl.DrawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, nil)

        gl.UseProgram(font_shader_program)

        buffer : [512]byte
        prefix := "  Level: "
        value := strings.concatenate({prefix, parameter_string_by_normalised_value(.Gain, buffer[:], normalise_parameter(.Gain, state.param_cache[.Gain]))})
        x : f32 = -string_width_in_pixels(prefix, &font_maps)
        render_string(value, &font_maps, x, -300.0, font_vao, font_colour)

        help_text :: "Click for Tone!"
        x = -string_width_in_pixels(help_text, &font_maps) / 2.0
        if bypass do render_string(help_text, &font_maps, x, 300.0, font_vao, font_colour)

        glx.SwapBuffers ( state.display, auto_cast state.window );
        xlib.Sync(state.display)

        // sleep
        end := time.now()
        diff := time.duration_nanoseconds(time.diff (start, end))
        fps_ns :i64 = 1 / (1_000_000 * 60)
        if diff < fps_ns do time.sleep(auto_cast (fps_ns - diff))
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
    thread.destroy(gui.thread_handle)
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
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, controller) - offset_of(Controller, view))
    v: ^View = auto_cast this
    v^ = {}
    init_view(v)
    gui_state := &v.gui.state
    gui_state.audio_to_gui = &plugin.state.audio_to_gui
    gui_state.gui_to_audio = &plugin.state.gui_to_audio
    intrinsics.atomic_store(&plugin.state.gui_active, true)
    for p in ParameterId do v.gui.state.param_cache[p] = intrinsics.atomic_load(&plugin.state.param_values[p])
    start_gui(&v.gui, handle)
    return vst3.Result.Ok
}

removed :: proc "c" (this: rawptr) -> vst3.Result {
    context = runtime.default_context()
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, controller) - offset_of(Controller, view))
    v: ^View = auto_cast this
    finish_gui(&v.gui)
    intrinsics.atomic_store(&plugin.state.gui_active, false)
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
    v: ^View = auto_cast this
    state := &v.gui.state
    size.left = 0 
    size.top = 0
    size.right = GuiInitialWidth
    size.bottom = GuiInitialHeight
    return vst3.Result.Ok
}

on_size :: proc "c" (this: rawptr, new_size: ^vst3.ViewRect) -> vst3.Result {
    v: ^View = auto_cast this
    resize_gui(&v.gui, GuiInitialWidth, GuiInitialHeight)
    return vst3.Result.Ok
}

on_focus :: proc "c" (rawptr, u8) -> vst3.Result {
    return vst3.Result.NotImplemented
}

set_frame :: proc "c" (rawptr, ^vst3.IPlugFrame) -> vst3.Result {
    return vst3.Result.NotImplemented
}

can_resize :: proc "c" (rawptr) -> vst3.Result {
    return vst3.Result.False
}

check_size_constraint :: proc "c" (this: rawptr, new_size: ^vst3.ViewRect) -> vst3.Result {
    return vst3.Result.NotImplemented
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
    v.gui.state.width = GuiInitialWidth
    v.gui.state.height = GuiInitialHeight
}

// Processor
// ===========
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
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, processor))
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
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, processor))
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
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, processor))
    state := &plugin.state
    state.sample_rate = setup.sample_rate
    return vst3.Result.Ok
}

set_processing :: proc "c" (this: rawptr, state: u8) -> vst3.Result {
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, processor))
    plugin.state.processing = auto_cast state 
    return vst3.Result.Ok
}

send_parameter_to_host :: proc "contextless" (changes: ^vst3.IParameterChanges, p: ParameterId, v: f64) {
    index := i32(0)
    id := u32(p)
    queue := changes->add_parameter_data(&id, &index)
    queue->add_point(0, normalise_parameter(p, v), &index)
}

process :: proc "c" (this: rawptr, data: ^vst3.ProcessData) -> vst3.Result #no_bounds_check {
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, processor))
    state := &plugin.state

    @static param_cache := [ParameterId]f64{}
    for p in ParameterId do param_cache[p] = intrinsics.atomic_load(&state.param_values[p])

    gui_active := intrinsics.atomic_load(&state.gui_active)

    // host parameter updating 
    input_changes := data.inputParameterChanges
    num_params := input_changes->get_parameter_count()
    for i in 0..<num_params {
        queue := input_changes->get_parameter_data(i) 
        point_count := queue->get_point_count()
        for p in 0..<point_count {
            value, offset := f64(0), i32(0)
            queue->get_point(p, &offset, &value)
            param_id := to_parameter_id(queue->get_parameter_id()) or_continue
            denorm := denormalise_parameter(param_id, value)
            param_cache[param_id] = denorm
            if gui_active do push_parameter_update(&state.audio_to_gui[param_id], denorm)
        }
    }

    // our parameter updating
    output_changes := data.outputParameterChanges
    for p in ParameterId {
        // gui changes
        for {
            v := pop_parameter_update(&state.gui_to_audio[p]) or_break
            param_cache[p] = v
            send_parameter_to_host(output_changes, p, v)
        }

        // disk changes
        for {
            v := pop_parameter_update(&state.controller_to_audio[p]) or_break
            param_cache[p] = v
            push_parameter_update(&state.audio_to_gui[p], v)
            send_parameter_to_host(output_changes, p, v)
        }

        // set interpolators
        value := normalise_parameter(p, param_cache[p])
        if p == .Bypass do value = 1.0 - value
        set_interpolator_target(&state.interpolators[p], value, state.sample_rate) 
    }

    // audio processing
    num_samples := data.num_samples
    num_inputs := data.num_inputs
    num_outputs := data.num_outputs
    bus_outputs := data.outputs[:num_outputs]

    for bus in bus_outputs {
        num_channels := bus.num_channels
        if data.symbolic_sample_size == .Sample32 {
             channels := bus.buffers_32[:num_channels]
             for &channel, index in channels {
                 if index == 0 {
                     samples := channel[:num_samples]
                     for &sample, index  in samples do sample = sample_tick(state, f32)
                 } else {
                     copy_slice(channel[:num_samples], channels[0][:num_samples])
                 }
             }
        } else {
             channels := bus.buffers_64[:num_channels]
             for &channel, index in channels {
                 if index == 0 {
                     samples := channel[:num_samples]
                     for &sample, index  in samples do sample = sample_tick(state, f64)
                 } else {
                     copy_slice(channel[:num_samples], channels[0][:num_samples])
                 }
             }
        }
    }

    for p in ParameterId do intrinsics.atomic_store(&state.param_values[p], param_cache[p])
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

// Controller 
// ===========
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

controller_set_state :: proc "c" (this: rawptr, stream: ^vst3.IBStream) -> vst3.Result {
    context = runtime.default_context()
    if stream == nil do return vst3.Result.InvalidArgument
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, controller))
    num_read := i32(0)
    for p in ParameterId {
        param := i32(p)
        value := f64(0) 
        stream->read(&param, size_of(i32), &num_read)
        if num_read == 0 do continue
        stream->read(&value, size_of(f64) , &num_read)
        if num_read == 0 do continue
        push_parameter_update(&plugin.state.controller_to_audio[p], value) 
    }
    return vst3.Result.Ok
}

controller_get_state :: proc "c" (this: rawptr, stream: ^vst3.IBStream) -> vst3.Result {
    context = runtime.default_context()
    if stream == nil do return vst3.Result.InvalidArgument
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, controller))
    num_written := i32(0)
    for p in ParameterId {
        param := i32(p)
        value := intrinsics.atomic_load(&plugin.state.param_values[p])
        stream->write(&param, size_of(i32), &num_written)
        if num_written == 0 do continue
        stream->write(&value, size_of(f64), &num_written)
        if num_written == 0 do continue
    }
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
    p, err := to_parameter_id(id)
    if err != nil do return 0 
    return normalise_parameter(p, value)
}

get_param_normalised :: proc "c" (this: rawptr, id: u32) -> f64 {
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, controller))
    p, err := to_parameter_id(id)
    if err != nil do return 0 
    v := intrinsics.atomic_load(&plugin.state.param_values[p])
    return normalise_parameter(p, v)
}

set_param_normalised :: proc "c" (this: rawptr, id: u32, value: f64) -> vst3.Result {
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, controller))
    p := to_parameter_id(id) or_return
    v := denormalise_parameter(p, value)
    intrinsics.atomic_store(&plugin.state.param_values[p], v)
    return vst3.Result.Ok
}

set_component_handler :: proc "c" (rawptr, ^vst3.IComponentHandler) -> vst3.Result {
    return vst3.Result.NotImplemented
}

create_view :: proc "c" (this: rawptr, name: cstring) -> ^vst3.IPlugView {
    plugin: ^Plugin = auto_cast (uintptr(this) - offset_of(Plugin, controller))
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

// Component 
// ===========

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

// Plugin
// ===========
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

// Factory 
// ========
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

// Entry
// ===========
@export ModuleEntry :: proc "c" () -> bool {
    return true
}

@export ModuleExit :: proc "c" () -> bool {
    return true
}

@export GetPluginFactory :: proc "c" () -> ^vst3.IPluginFactory3 {
    context = runtime.default_context()
    @static x: ^Factory
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
        x->add_ref()
    }
    return auto_cast x
}
