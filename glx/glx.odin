package glx

// foreign import glx "system:GLX"

import "core:c"
import "vendor:x11/xlib"

foreign import gl "system:GL"

VERSION_1_1	 :: 1
VERSION_1_2	 :: 1
VERSION_1_3	 :: 1
VERSION_1_4	 :: 1

EXTENSION_NAME   :: "GLX"

/*
 * Tokens for glXChooseVisual and glXGetConfig:
 */
USE_GL	 :: 1
BUFFER_SIZE	 :: 2
LEVEL	 :: 3
RGBA	 :: 4
DOUBLEBUFFER :: 5
STEREO	 :: 6
AUX_BUFFERS	 :: 7
RED_SIZE	 :: 8
GREEN_SIZE	 :: 9
BLUE_SIZE	 :: 10
ALPHA_SIZE	 :: 11
DEPTH_SIZE	 :: 12
STENCIL_SIZE :: 13
ACCUM_RED_SIZE :: 14
ACCUM_GREEN_SIZE :: 15
ACCUM_BLUE_SIZE :: 16
ACCUM_ALPHA_SIZE :: 17


/*
 * Error codes returned by glXGetConfig:
 */
BAD_SCREEN	 :: 1
BAD_ATTRIBUTE :: 2
NO_EXTENSION :: 3
BAD_VISUAL	 :: 4
BAD_CONTEXT	 :: 5
BAD_VALUE        :: 6
BAD_ENUM	 :: 7


/*
 * GLX 1.1 and later:
 */
VENDOR	 :: 1
VERSION	 :: 2
EXTENSIONS 	 :: 3


/*
 * GLX 1.3 and later:
 */ 
CONFIG_CAVEAT	 :: 0x20
DONT_CARE		 :: 0xFFFFFFFF
X_VISUAL_TYPE	 :: 0x22
TRANSPARENT_TYPE	 :: 0x23
TRANSPARENT_INDEX_VALUE :: 0x24
TRANSPARENT_RED_VALUE :: 0x25
TRANSPARENT_GREEN_VALUE :: 0x26
TRANSPARENT_BLUE_VALUE :: 0x27
TRANSPARENT_ALPHA_VALUE :: 0x28
WINDOW_BIT		 :: 0x00000001
PIXMAP_BIT		 :: 0x00000002
PBUFFER_BIT		 :: 0x00000004
AUX_BUFFERS_BIT	 :: 0x00000010
FRONT_LEFT_BUFFER_BIT :: 0x00000001
FRONT_RIGHT_BUFFER_BIT :: 0x00000002
BACK_LEFT_BUFFER_BIT :: 0x00000004
BACK_RIGHT_BUFFER_BIT :: 0x00000008
DEPTH_BUFFER_BIT	 :: 0x00000020
STENCIL_BUFFER_BIT	 :: 0x00000040
ACCUM_BUFFER_BIT	 :: 0x00000080
NONE		 :: 0x8000
SLOW_CONFIG		 :: 0x8001
TRUE_COLOR		 :: 0x8002
DIRECT_COLOR	 :: 0x8003
PSEUDO_COLOR	 :: 0x8004
STATIC_COLOR	 :: 0x8005
GRAY_SCALE		 :: 0x8006
STATIC_GRAY		 :: 0x8007
TRANSPARENT_RGB	 :: 0x8008
TRANSPARENT_INDEX	 :: 0x8009
VISUAL_ID		 :: 0x800B
SCREEN		 :: 0x800C
NON_CONFORMANT_CONFIG :: 0x800D
DRAWABLE_TYPE	 :: 0x8010
RENDER_TYPE		 :: 0x8011
X_RENDERABLE	 :: 0x8012
FBCONFIG_ID		 :: 0x8013
RGBA_TYPE		 :: 0x8014
COLOR_INDEX_TYPE	 :: 0x8015
MAX_PBUFFER_WIDTH	 :: 0x8016
MAX_PBUFFER_HEIGHT	 :: 0x8017
MAX_PBUFFER_PIXELS	 :: 0x8018
PRESERVED_CONTENTS	 :: 0x801B
LARGEST_PBUFFER	 :: 0x801C
WIDTH		 :: 0x801D
HEIGHT		 :: 0x801E
EVENT_MASK		 :: 0x801F
DAMAGED		 :: 0x8020
SAVED		 :: 0x8021
WINDOW		 :: 0x8022
PBUFFER		 :: 0x8023
PBUFFER_HEIGHT              :: 0x8040
PBUFFER_WIDTH               :: 0x8041
RGBA_BIT		 :: 0x00000001
COLOR_INDEX_BIT	 :: 0x00000002
PBUFFER_CLOBBER_MASK :: 0x08000000

/*
 * GLX 1.4 and later:
 */
SAMPLE_BUFFERS              :: 0x186a0 /*100000*/
SAMPLES                     :: 0x186a1 /*100001*/

Context :: rawptr 
FBConfig :: rawptr 
XID :: c.ulong
Pixmap :: XID
Drawable :: XID
/* GLX 1.3 and later */
// typedef struct __GLXFBConfigRec *GLXFBConfig;
FBConfigID :: XID
ContextID :: XID
Window :: XID
Pbuffer :: XID


/*
** Events.
** __GLX_NUMBER_EVENTS is set to 17 to account for the BufferClobberSGIX
**  event - this helps initialization if the server supports the pbuffer
**  extension and the client doesn't.
*/
PbufferClobber :: 0
BufferSwapComplete :: 1

NUMBER_EVENTS :: 17

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
}

//
//
//
//
//
// /* GLX 1.3 function pointer typedefs */
// typedef GLXFBConfig * (* PFNGLXGETFBCONFIGSPROC) (Display *dpy, int screen, int *nelements);
// typedef GLXFBConfig * (* PFNGLXCHOOSEFBCONFIGPROC) (Display *dpy, int screen, const int *attrib_list, int *nelements);
// typedef int (* PFNGLXGETFBCONFIGATTRIBPROC) (Display *dpy, GLXFBConfig config, int attribute, int *value);
// typedef XVisualInfo * (* PFNGLXGETVISUALFROMFBCONFIGPROC) (Display *dpy, GLXFBConfig config);
// typedef GLXWindow (* PFNGLXCREATEWINDOWPROC) (Display *dpy, GLXFBConfig config, Window win, const int *attrib_list);
// typedef void (* PFNGLXDESTROYWINDOWPROC) (Display *dpy, GLXWindow win);
// typedef GLXPixmap (* PFNGLXCREATEPIXMAPPROC) (Display *dpy, GLXFBConfig config, Pixmap pixmap, const int *attrib_list);
// typedef void (* PFNGLXDESTROYPIXMAPPROC) (Display *dpy, GLXPixmap pixmap);
// typedef GLXPbuffer (* PFNGLXCREATEPBUFFERPROC) (Display *dpy, GLXFBConfig config, const int *attrib_list);
// typedef void (* PFNGLXDESTROYPBUFFERPROC) (Display *dpy, GLXPbuffer pbuf);
// typedef void (* PFNGLXQUERYDRAWABLEPROC) (Display *dpy, GLXDrawable draw, int attribute, unsigned int *value);
// typedef GLXContext (* PFNGLXCREATENEWCONTEXTPROC) (Display *dpy, GLXFBConfig config, int render_type, GLXContext share_list, Bool direct);
// typedef Bool (* PFNGLXMAKECONTEXTCURRENTPROC) (Display *dpy, GLXDrawable draw, GLXDrawable read, GLXContext ctx);
// typedef GLXDrawable (* PFNGLXGETCURRENTREADDRAWABLEPROC) (void);
// typedef Display * (* PFNGLXGETCURRENTDISPLAYPROC) (void);
// typedef int (* PFNGLXQUERYCONTEXTPROC) (Display *dpy, GLXContext ctx, int attribute, int *value);
// typedef void (* PFNGLXSELECTEVENTPROC) (Display *dpy, GLXDrawable draw, unsigned long event_mask);
// typedef void (* PFNGLXGETSELECTEDEVENTPROC) (Display *dpy, GLXDrawable draw, unsigned long *event_mask);
//
//
// /*
//  * ARB 2. GLX_ARB_get_proc_address
//  */
// #ifndef GLX_ARB_get_proc_address
// #define GLX_ARB_get_proc_address 1
//
// typedef void (*__GLXextFuncPtr)(void);
// extern __GLXextFuncPtr glXGetProcAddressARB (const GLubyte *);
//
// #endif /* GLX_ARB_get_proc_address */
//
//
//
// /* GLX 1.4 and later */
// extern void (*glXGetProcAddress(const GLubyte *procname))( void );
//
// /* GLX 1.4 function pointer typedefs */
// typedef __GLXextFuncPtr (* PFNGLXGETPROCADDRESSPROC) (const GLubyte *procName);
//
//
// #ifndef GLX_GLXEXT_LEGACY
//
// #include <GL/glxext.h>
//
// #endif /* GLX_GLXEXT_LEGACY */
//
//
// /**
//  ** The following aren't in glxext.h yet.
//  **/
//
//
// /*
//  * ???. GLX_NV_vertex_array_range
//  */
// #ifndef GLX_NV_vertex_array_range
// #define GLX_NV_vertex_array_range
//
// extern void *glXAllocateMemoryNV(GLsizei size, GLfloat readfreq, GLfloat writefreq, GLfloat priority);
// extern void glXFreeMemoryNV(GLvoid *pointer);
// typedef void * ( * PFNGLXALLOCATEMEMORYNVPROC) (GLsizei size, GLfloat readfreq, GLfloat writefreq, GLfloat priority);
// typedef void ( * PFNGLXFREEMEMORYNVPROC) (GLvoid *pointer);
//
// #endif /* GLX_NV_vertex_array_range */
//
//
// /*
//  * ARB ?. GLX_ARB_render_texture
//  * XXX This was never finalized!
//  */
// #ifndef GLX_ARB_render_texture
// #define GLX_ARB_render_texture 1
//
// extern Bool glXBindTexImageARB(Display *dpy, GLXPbuffer pbuffer, int buffer);
// extern Bool glXReleaseTexImageARB(Display *dpy, GLXPbuffer pbuffer, int buffer);
// extern Bool glXDrawableAttribARB(Display *dpy, GLXDrawable draw, const int *attribList);
//
// #endif /* GLX_ARB_render_texture */
//
//
// /*
//  * Remove this when glxext.h is updated.
//  */
// #ifndef GLX_NV_float_buffer
// #define GLX_NV_float_buffer 1
//
// #define GLX_FLOAT_COMPONENTS_NV         0x20B0
//
// #endif /* GLX_NV_float_buffer */
//
//
//
// /*
//  * #?. GLX_MESA_swap_frame_usage
//  */
// #ifndef GLX_MESA_swap_frame_usage
// #define GLX_MESA_swap_frame_usage 1
//
// extern int glXGetFrameUsageMESA(Display *dpy, GLXDrawable drawable, float *usage);
// extern int glXBeginFrameTrackingMESA(Display *dpy, GLXDrawable drawable);
// extern int glXEndFrameTrackingMESA(Display *dpy, GLXDrawable drawable);
// extern int glXQueryFrameTrackingMESA(Display *dpy, GLXDrawable drawable, int64_t *swapCount, int64_t *missedFrames, float *lastMissedUsage);
//
// typedef int (*PFNGLXGETFRAMEUSAGEMESAPROC) (Display *dpy, GLXDrawable drawable, float *usage);
// typedef int (*PFNGLXBEGINFRAMETRACKINGMESAPROC)(Display *dpy, GLXDrawable drawable);
// typedef int (*PFNGLXENDFRAMETRACKINGMESAPROC)(Display *dpy, GLXDrawable drawable);
// typedef int (*PFNGLXQUERYFRAMETRACKINGMESAPROC)(Display *dpy, GLXDrawable drawable, int64_t *swapCount, int64_t *missedFrames, float *lastMissedUsage);
//
// #endif /* GLX_MESA_swap_frame_usage */
//
//
//
// /*
//  * #?. GLX_MESA_swap_control
//  */
// #ifndef GLX_MESA_swap_control
// #define GLX_MESA_swap_control 1
//
// extern int glXSwapIntervalMESA(unsigned int interval);
// extern int glXGetSwapIntervalMESA(void);
//
// typedef int (*PFNGLXSWAPINTERVALMESAPROC)(unsigned int interval);
// typedef int (*PFNGLXGETSWAPINTERVALMESAPROC)(void);
//
// #endif /* GLX_MESA_swap_control */
//
//
//
// /*
//  * #?. GLX_EXT_texture_from_pixmap
//  * XXX not finished?
//  */
// #ifndef GLX_EXT_texture_from_pixmap
// #define GLX_EXT_texture_from_pixmap 1
//
// #define GLX_BIND_TO_TEXTURE_RGB_EXT        0x20D0
// #define GLX_BIND_TO_TEXTURE_RGBA_EXT       0x20D1
// #define GLX_BIND_TO_MIPMAP_TEXTURE_EXT     0x20D2
// #define GLX_BIND_TO_TEXTURE_TARGETS_EXT    0x20D3
// #define GLX_Y_INVERTED_EXT                 0x20D4
//
// #define GLX_TEXTURE_FORMAT_EXT             0x20D5
// #define GLX_TEXTURE_TARGET_EXT             0x20D6
// #define GLX_MIPMAP_TEXTURE_EXT             0x20D7
//
// #define GLX_TEXTURE_FORMAT_NONE_EXT        0x20D8
// #define GLX_TEXTURE_FORMAT_RGB_EXT         0x20D9
// #define GLX_TEXTURE_FORMAT_RGBA_EXT        0x20DA
//
// #define GLX_TEXTURE_1D_BIT_EXT             0x00000001
// #define GLX_TEXTURE_2D_BIT_EXT             0x00000002
// #define GLX_TEXTURE_RECTANGLE_BIT_EXT      0x00000004
//
// #define GLX_TEXTURE_1D_EXT                 0x20DB
// #define GLX_TEXTURE_2D_EXT                 0x20DC
// #define GLX_TEXTURE_RECTANGLE_EXT          0x20DD
//
// #define GLX_FRONT_LEFT_EXT                 0x20DE
// #define GLX_FRONT_RIGHT_EXT                0x20DF
// #define GLX_BACK_LEFT_EXT                  0x20E0
// #define GLX_BACK_RIGHT_EXT                 0x20E1
// #define GLX_FRONT_EXT                      GLX_FRONT_LEFT_EXT
// #define GLX_BACK_EXT                       GLX_BACK_LEFT_EXT
// #define GLX_AUX0_EXT                       0x20E2
// #define GLX_AUX1_EXT                       0x20E3 
// #define GLX_AUX2_EXT                       0x20E4 
// #define GLX_AUX3_EXT                       0x20E5 
// #define GLX_AUX4_EXT                       0x20E6 
// #define GLX_AUX5_EXT                       0x20E7 
// #define GLX_AUX6_EXT                       0x20E8
// #define GLX_AUX7_EXT                       0x20E9 
// #define GLX_AUX8_EXT                       0x20EA 
// #define GLX_AUX9_EXT                       0x20EB
//
// extern void glXBindTexImageEXT(Display *dpy, GLXDrawable drawable, int buffer, const int *attrib_list);
// extern void glXReleaseTexImageEXT(Display *dpy, GLXDrawable drawable, int buffer);
//
// #endif /* GLX_EXT_texture_from_pixmap */
//
//
//
//
// /*** Should these go here, or in another header? */
// /*
// ** GLX Events
// */
// typedef struct {
//     int event_type;		/* GLX_DAMAGED or GLX_SAVED */
//     int draw_type;		/* GLX_WINDOW or GLX_PBUFFER */
//     unsigned long serial;	/* # of last request processed by server */
//     Bool send_event;		/* true if this came for SendEvent request */
//     Display *display;		/* display the event was read from */
//     GLXDrawable drawable;	/* XID of Drawable */
//     unsigned int buffer_mask;	/* mask indicating which buffers are affected */
//     unsigned int aux_buffer;	/* which aux buffer was affected */
//     int x, y;
//     int width, height;
//     int count;			/* if nonzero, at least this many more */
// } GLXPbufferClobberEvent;
//
// typedef struct {
//     int type;
//     unsigned long serial;	/* # of last request processed by server */
//     Bool send_event;		/* true if this came from a SendEvent request */
//     Display *display;		/* Display the event was read from */
//     GLXDrawable drawable;	/* drawable on which event was requested in event mask */
//     int event_type;
//     int64_t ust;
//     int64_t msc;
//     int64_t sbc;
// } GLXBufferSwapComplete;
//
// typedef union __GLXEvent {
//     GLXPbufferClobberEvent glxpbufferclobber;
//     GLXBufferSwapComplete glxbufferswapcomplete;
//     long pad[24];
// } GLXEvent;
//
// #ifdef __cplusplus
// }
// #endif
//
// #endif
