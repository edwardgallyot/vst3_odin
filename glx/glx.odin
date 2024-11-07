package glx

// foreign import glx "system:GLX"

import "core:c"
import "vendor:x11/xlib"

foreign import gl "system:GL"

CONTEXT_MAJOR_VERSION_ARB :: 0x2091
CONTEXT_MINOR_VERSION_ARB :: 0x2092
VERSION_1_1 :: 1
VERSION_1_2 :: 1
VERSION_1_3 :: 1
VERSION_1_4 :: 1
EXTENSION_NAME :: "GLX"
USE_GL :: 1
BUFFER_SIZE :: 2
LEVEL :: 3
RGBA :: 4
DOUBLEBUFFER :: 5
STEREO :: 6
AUX_BUFFERS :: 7
RED_SIZE :: 8
GREEN_SIZE :: 9
BLUE_SIZE :: 10
ALPHA_SIZE :: 11
DEPTH_SIZE :: 12
STENCIL_SIZE :: 13
ACCUM_RED_SIZE :: 14
ACCUM_GREEN_SIZE :: 15
ACCUM_BLUE_SIZE :: 16
ACCUM_ALPHA_SIZE :: 17
BAD_SCREEN :: 1
BAD_ATTRIBUTE :: 2
NO_EXTENSION :: 3
BAD_VISUAL :: 4
BAD_CONTEXT :: 5
BAD_VALUE :: 6
BAD_ENUM :: 7
VENDOR :: 1
VERSION	:: 2
EXTENSIONS :: 3
CONFIG_CAVEAT :: 0x20
DONT_CARE :: 0xFFFFFFFF
X_VISUAL_TYPE :: 0x22
TRANSPARENT_TYPE :: 0x23
TRANSPARENT_INDEX_VALUE :: 0x24
TRANSPARENT_RED_VALUE :: 0x25
TRANSPARENT_GREEN_VALUE :: 0x26
TRANSPARENT_BLUE_VALUE :: 0x27
TRANSPARENT_ALPHA_VALUE :: 0x28
WINDOW_BIT :: 0x00000001
PIXMAP_BIT :: 0x00000002
PBUFFER_BIT	:: 0x00000004
AUX_BUFFERS_BIT :: 0x00000010
FRONT_LEFT_BUFFER_BIT :: 0x00000001
FRONT_RIGHT_BUFFER_BIT :: 0x00000002
BACK_LEFT_BUFFER_BIT :: 0x00000004
BACK_RIGHT_BUFFER_BIT :: 0x00000008
DEPTH_BUFFER_BIT :: 0x00000020
STENCIL_BUFFER_BIT :: 0x00000040
ACCUM_BUFFER_BIT :: 0x00000080
NONE :: 0x8000
SLOW_CONFIG	:: 0x8001
TRUE_COLOR :: 0x8002
DIRECT_COLOR :: 0x8003
PSEUDO_COLOR :: 0x8004
STATIC_COLOR :: 0x8005
GRAY_SCALE :: 0x8006
STATIC_GRAY	:: 0x8007
TRANSPARENT_RGB	:: 0x8008
TRANSPARENT_INDEX :: 0x8009
VISUAL_ID :: 0x800B
SCREEN :: 0x800C
NON_CONFORMANT_CONFIG :: 0x800D
DRAWABLE_TYPE :: 0x8010
RENDER_TYPE	:: 0x8011
X_RENDERABLE :: 0x8012
FBCONFIG_ID :: 0x8013
RGBA_TYPE :: 0x8014
COLOR_INDEX_TYPE :: 0x8015
MAX_PBUFFER_WIDTH :: 0x8016
MAX_PBUFFER_HEIGHT :: 0x8017
MAX_PBUFFER_PIXELS :: 0x8018
PRESERVED_CONTENTS :: 0x801B
LARGEST_PBUFFER	:: 0x801C
WIDTH :: 0x801D
HEIGHT :: 0x801E
EVENT_MASK :: 0x801F
DAMAGED :: 0x8020
SAVED :: 0x8021
WINDOW :: 0x8022
PBUFFER	:: 0x8023
PBUFFER_HEIGHT :: 0x8040
PBUFFER_WIDTH :: 0x8041
RGBA_BIT :: 0x00000001
COLOR_INDEX_BIT :: 0x00000002
PBUFFER_CLOBBER_MASK :: 0x08000000
SAMPLE_BUFFERS :: 0x186a0 
SAMPLES :: 0x186a1 
Context :: rawptr 
FBConfig :: rawptr 
XID :: c.ulong
Pixmap :: XID
Drawable :: XID
FBConfigID :: XID
ContextID :: XID
Window :: XID
Pbuffer :: XID
PbufferClobber :: 0
BufferSwapIsComplete :: 1
NUMBER_EVENTS :: 17
extFuncPtr :: proc "system" ()

foreign gl {
    @(link_name="glXChooseVisual") ChooseVisual :: proc "system" (^xlib.Display, i32, [^]i32) -> ^xlib.XVisualInfo ---
    @(link_name="glXCreateContext") CreateContext :: proc "system" ( ^xlib.Display, ^xlib.XVisualInfo, Context, c.bool) -> Context ---
    @(link_name="glXDestroyContext") DestroyContext :: proc "system" ( ^xlib.Display, Context) ---
    @(link_name="glXMakeCurrent") MakeCurrent :: proc "system" ( ^xlib.Display, Drawable, Context) -> c.bool ---
    @(link_name="glXCopyContext") CopyContext :: proc "system" ( ^xlib.Display, Context, Context, c.ulong)  ---
    @(link_name="glXSwapBuffers") SwapBuffers :: proc "system" ( ^xlib.Display, Drawable) ---
    @(link_name="glXCreateGLXPixmap") CreateGLXPixmap :: proc "system" ( ^xlib.Display, ^xlib.XVisualInfo, xlib.Pixmap) -> Pixmap  ---
    @(link_name="glXDestroyGLXPixmap") DestroyGLXPixmap :: proc "system" ( ^xlib.Display, Pixmap) ---
    @(link_name="glXQueryExtension") QueryExtension :: proc "system" ( ^xlib.Display, ^i32, ^i32) -> c.bool ---
    @(link_name="glXQueryVersion") QueryVersion :: proc "system" ( ^xlib.Display, ^i32, ^i32) -> c.bool ---
    @(link_name="glXIsDirect") IsDirect :: proc "system" ( ^xlib.Display, Context) -> c.bool ---
    @(link_name="glXGetConfig") GetConfig :: proc "system" ( ^xlib.Display, ^xlib.XVisualInfo, i32,^i32) -> i32  ---
    @(link_name="glXGetCurrentContext") GetCurrentContext :: proc "system" () -> Context  ---
    @(link_name="glXGetCurrentDrawable") GetCurrentDrawable :: proc "system" () -> xlib.Drawable  ---
    @(link_name="glXWaitGL") WaitGL :: proc "system" () ---
    @(link_name="glXWaitX") WaitX :: proc "system" () ---
    @(link_name="glXUseXFont") UseXFont :: proc "system" (xlib.Font, i32, i32, i32)  ---
    @(link_name="glXQueryExtensionsString") QueryExtensionsString :: proc "system" (^xlib.Display, i32) -> cstring ---
    @(link_name="glXQueryServerString") QueryServerString :: proc "system" (^xlib.Display, i32, i32) -> cstring ---
    @(link_name="glXGetClientString") GetClientString :: proc "system"(^xlib.Display, i32) -> cstring ---
    @(link_name="glXGetCurrentDisplay") GetCurrentDisplay :: proc "system" () -> ^xlib.Display  ---
    @(link_name="glXChooseFBConfig") ChooseFBConfig :: proc "system" (^xlib.Display, i32, [^]i32, ^i32) -> [^]FBConfig  ---
    @(link_name="glXGetFBConfigAttrib") GetFBConfigAttrib :: proc "system" (^xlib.Display, FBConfig, i32, ^i32) -> int  ---
    @(link_name="glXGetFBConfigs") GetFBConfigs :: proc "system" (^xlib.Display, i32, ^i32) -> ^FBConfig  ---
    @(link_name="glXGetVisualFromFBConfig") GetVisualFromFBConfig :: proc "system" (^xlib.Display, FBConfig) -> ^xlib.XVisualInfo  ---
    @(link_name="glXCreateWindow") CreateWindow :: proc "system" ( ^xlib.Display, FBConfig, xlib.Window, ^i32) -> Window  ---
    @(link_name="glXDestroyWindow") DestroyWindow :: proc "system" (^xlib.Display, Window) ---
    @(link_name="glXCreatePixmap") CreatePixmap :: proc "system" (^xlib.Display, FBConfig, xlib.Pixmap, ^i32) -> Pixmap  ---
    @(link_name="glXDestroyPixmap") DestroyPixmap :: proc "system" (^xlib.Display, Pixmap) ---
    @(link_name="glXCreatePbuffer") CreatePbuffer :: proc "system" (^xlib.Display, FBConfig, ^i32) -> Pbuffer  ---
    @(link_name="glXDestroyPbuffer") DestroyPbuffer :: proc "system" (^xlib.Display, Pbuffer) ---
    @(link_name="glXQueryDrawable") QueryDrawable :: proc "system" (^xlib.Display, Drawable, i32, ^u32) ---
    @(link_name="glXCreateNewContext") CreateNewContext :: proc "system" (^xlib.Display, FBConfig, i32, Context, c.bool) -> Context  ---
    @(link_name="glXMakeContextCurrent") MakeContextCurrent :: proc "system" (^xlib.Display, Drawable, Drawable, Context) -> c.bool  ---
    @(link_name="glXGetCurrentReadDrawable") GetCurrentReadDrawable :: proc "system" () -> Drawable  ---
    @(link_name="glXQueryContext") QueryContext :: proc "system" (^xlib.Display, Context, i32, ^i32) -> i32 ---
    @(link_name="glXSelectEvent") SelectEvent :: proc "system" (^xlib.Display, Drawable, c.ulong)  ---
    @(link_name="glXGetSelectedEvent") GetSelectedEvent :: proc "system" (^xlib.Display, Drawable, ^c.ulong) ---
    @(link_name="glXGetProcAddressARB") GetProcAddressARB :: proc "system" (cstring) -> extFuncPtr ---
    @(link_name="glXGetProcAddress") GetProcAddress :: proc "system" (cstring) -> extFuncPtr ---
    @(link_name="glXBindTexImageEXT") BindTexImageEXT :: proc "system" (^xlib.Display, Drawable, i32, [^]i32) ---
    @(link_name="glXReleaseTexImageEXT") ReleaseTexImageEXT :: proc "system" (^xlib.Display, Drawable, i32) ---
    @(link_name="glXSwapIntervalMESA") SwapIntervalMESA ::proc "system"(u32) -> i32 ---
    @(link_name="glXGetSwapIntervalMESA") GetSwapIntervalMESA :: proc "system" () -> i32 ---
    @(link_name="glXAllocateMemoryNV") AllocateMemoryNV :: proc "system" (int, f32, f32, f32) -> rawptr ---
    @(link_name="glXFreeMemoryNV") FreeMemoryNV :: proc "system" (rawptr) ---
    @(link_name="glXBindTexImageARB") BindTexImageARB :: proc "system" (^xlib.Display, Pbuffer, i32)-> c.bool ---
    @(link_name="glXReleaseTexImageARB") ReleaseTexImageARB :: proc "system" (^xlib.Display, Pbuffer, i32) -> c.bool ---
    @(link_name="glXDrawableAttribARB") DrawableAttribARB :: proc "system" (^xlib.Display, Drawable, [^]i32) -> c.bool ---
    @(link_name="glXGetFrameUsageMESA") GetFrameUsageMESA :: proc "system" (^xlib.Display, Drawable, ^f32) -> i32 ---
    @(link_name="glXBeginFrameTrackingMESA") BeginFrameTrackingMESA :: proc "system" (^xlib.Display, Drawable) -> i32 ---
    @(link_name="glXEndFrameTrackingMESA") EndFrameTrackingMESA :: proc "system" (^xlib.Display, Drawable) -> i32 ---
    @(link_name="glXQueryFrameTrackingMESA") QueryFrameTrackingMESA :: proc "system" (^xlib.Display, Drawable, ^i64, ^i64, ^f32) -> i32 ---
}

GETFBCONFIGSPROC :: proc "system" (^xlib.Display, i32, ^i32) -> ^FBConfig    
CHOOSEFBCONFIGPROC :: proc "system" (^xlib.Display, i32, [^]i32, ^i32) -> [^]FBConfig   
GETFBCONFIGATTRIBPROC :: proc "system" (^xlib.Display, FBConfig, i32, ^i32) -> int  
GETVISUALFROMFBCONFIGPROC :: proc "system" (^xlib.Display, FBConfig) -> ^xlib.XVisualInfo  
CREATEWINDOWPROC :: proc "system" (^xlib.Display, FBConfig, xlib.Window, ^i32) -> Window
DESTROYWINDOWPROC :: proc "system" (^xlib.Display, Window)
CREATEPIXMAPPROC :: proc "system" (^xlib.Display, FBConfig, xlib.Pixmap, ^i32) -> Pixmap 
DESTROYPIXMAPPROC :: proc "system" (^xlib.Display, Pixmap) 
CREATEPBUFFERPROC :: proc "system" (^xlib.Display, FBConfig, [^]i32) -> Pbuffer 
DESTROYPBUFFERPROC :: proc "system" (^xlib.Display, Pbuffer) 
QUERYDRAWABLEPROC :: proc "system" (^xlib.Display, Drawable, i32, ^u32)
CREATENEWCONTEXTPROC :: proc "system" (^xlib.Display, FBConfig, i32, Context, c.bool) -> Context 
MAKECONTEXTCURRENTPROC :: proc "system" (^xlib.Display, Drawable, Drawable, Context)  -> c.bool 
GETCURRENTREADDRAWABLEPROC :: proc "system" () -> Drawable 
GETCURRENTDISPLAYPROC :: proc "system" () -> ^xlib.Display 
QUERYCONTEXTPROC :: proc "system" (^xlib.Display, Context, i32, ^i32) -> i32
SELECTEVENTPROC :: proc "system" (^xlib.Display, Drawable, xlib.EventMask) 
GETSELECTEDEVENTPROC :: proc "system" (^xlib.Display, Drawable, ^xlib.EventMask) 
GETPROCADDRESSPROC :: proc "system" (cstring) -> extFuncPtr 
ALLOCATEMEMORYNVPROC :: proc "system" (int, f32, f32, f32) -> rawptr
FREEMEMORYNVPROC :: proc "system" (rawptr) 
GETFRAMEUSAGEMESAPROC :: proc "system" (^xlib.Display, Drawable, ^f32) -> i32
BEGINFRAMETRACKINGMESAPROC :: proc "system" (^xlib.Display, Drawable) -> i32
ENDFRAMETRACKINGMESAPROC :: proc "system" (^xlib.Display, Drawable) -> i32
QUERYFRAMETRACKINGMESAPROC :: proc "system" (^xlib.Display, Drawable, ^i64, ^i64, ^f32) -> i32
SWAPINTERVALMESAPROC :: proc "system" (u32) -> i32
GETSWAPINTERVALMESAPROC :: proc "system" () -> i32

BIND_TO_TEXTURE_RGB_EXT :: 0x20D0
BIND_TO_TEXTURE_RGBA_EXT :: 0x20D1
BIND_TO_MIPMAP_TEXTURE_EXT :: 0x20D2
BIND_TO_TEXTURE_TARGETS_EXT :: 0x20D3
Y_INVERTED_EXT :: 0x20D4
TEXTURE_FORMAT_EXT :: 0x20D5
TEXTURE_TARGET_EXT :: 0x20D6
MIPMAP_TEXTURE_EXT :: 0x20D7
TEXTURE_FORMAT_NONE_EXT :: 0x20D8
TEXTURE_FORMAT_RGB_EXT :: 0x20D9
TEXTURE_FORMAT_RGBA_EXT :: 0x20DA
TEXTURE_1D_BIT_EXT :: 0x00000001
TEXTURE_2D_BIT_EXT :: 0x00000002
TEXTURE_RECTANGLE_BIT_EXT :: 0x00000004
TEXTURE_1D_EXT :: 0x20DB
TEXTURE_2D_EXT :: 0x20DC
TEXTURE_RECTANGLE_EXT :: 0x20DD
FRONT_LEFT_EXT :: 0x20DE
FRONT_RIGHT_EXT :: 0x20DF
BACK_LEFT_EXT :: 0x20E0
BACK_RIGHT_EXT :: 0x20E1
FRONT_EXT :: FRONT_LEFT_EXT
BACK_EXT :: BACK_LEFT_EXT
AUX0_EXT :: 0x20E2
AUX1_EXT :: 0x20E3 
AUX2_EXT :: 0x20E4 
AUX3_EXT :: 0x20E5 
AUX4_EXT :: 0x20E6 
AUX5_EXT :: 0x20E7 
AUX6_EXT :: 0x20E8
AUX7_EXT :: 0x20E9 
AUX8_EXT :: 0x20EA 
AUX9_EXT :: 0x20EB


PbufferClobberEvent :: struct {
    event_type: i32,		
    draw_type: i32,		
    serial: c.ulong,	
    send_event: c.bool,		
    display: ^xlib.Display,		
    drawable: Drawable,	
    buffer_mask: u32,	
    aux_buffer: u32,	
    x, y: i32,
    width, height: i32,
    count: i32,			
}


BufferSwapComplete :: struct {
    type: i32,
    serial: c.ulong,	
    send_event: c.bool,		
    display: ^xlib.Display,		
    drawable: Drawable,	
    event_type: i32,
    ust: i64,
    msc: i64,
    sbc: i64,
}

Event :: struct #raw_union {
    glxpbufferclobber: PbufferClobberEvent,
    glxbufferswapcomplete: BufferSwapComplete,
    pad: [24]c.long,
}

