package hardware_devices

import "core:thread"
import "../cairo"
import sdl "vendor:sdl3"
import "core:fmt"

MPCStudioDisplay :: struct {
    using display: cairo.Display,
    sdl_window: ^sdl.Window,
    sdl_renderer: ^sdl.Renderer,
    sdl_texture: ^sdl.Texture,
    sdl_surface: ^sdl.Surface,
    sdl_scale: f32,
    cairo_format: cairo.format_t,
    window_title: string,
    sRect : cairo.rectangle_t,
    dRect : sdl.FRect,
    event : sdl.Event,
    display_thread: ^thread.Thread,

}

createMPCStudioDisplay :: proc() -> ^MPCStudioDisplay {
    display := new(MPCStudioDisplay)
    cairo.configureDisplay(display, cairo.format_t.ARGB32, MPC_SCREEN_WIDTH, MPC_SCREEN_HEIGHT, cairo.BLACK)
    display.max_frames_per_second = 60 // Default to 60 FPS, can be overridden by user
    display.window_title = "MPC Studio Black"
    display.onInitialize = onInitializeMPCDisplay
    display.onDeInitialize = onDeInitializeMPCDisplay
    display.update = mpcStudioUpdate
    display.render = mpcStudioRender
    display.sdl_scale = 1.5
    // display.run = mpcStudioDisplayRun
    return display
}

onInitializeMPCDisplay :: proc(display_ptr: rawptr) {
    display := cast(^MPCStudioDisplay)display_ptr

    fmt.println("Initializing MPC Studio Display...")
    init_results := sdl.Init({.VIDEO})
    if !init_results {
        fmt.printf("Failed to initialize SDL: %s\n", sdl.GetError())
        return
    }
    display.sdl_window = new(sdl.Window)
    display.sdl_renderer = new(sdl.Renderer)
    success := sdl.CreateWindowAndRenderer(fmt.ctprint(display.window_title), i32(f32(display.size.x) * display.sdl_scale), i32(f32(display.size.y) * display.sdl_scale), {.OPENGL}, &display.sdl_window, &display.sdl_renderer)
    if !success {
        fmt.printf("Failed to create SDL window and renderer: %s\n", sdl.GetError())
        return
    }
    
    display.sdl_surface = sdl.CreateSurfaceFrom(display.size.x, display.size.y, sdl.PixelFormat.RGB24, cairo.image_surface_get_data(display.surface),  cairo.image_surface_get_stride(display.surface))
    display.sdl_texture = sdl.CreateTextureFromSurface(display.sdl_renderer, display.sdl_surface )

    display.sRect = cairo.rectangle_t{0, 0, f64(display.size.x), f64(display.size.y)}
    display.dRect = sdl.FRect{0, 0, f32(display.size.x) * display.sdl_scale, f32(display.size.y) * display.sdl_scale}
    
}

onDeInitializeMPCDisplay :: proc(display_ptr: rawptr) {
    display := cast(^MPCStudioDisplay)display_ptr
    if display.sdl_texture != nil {
        sdl.DestroyTexture(display.sdl_texture)
    }
   
    if display.sdl_renderer != nil {
        sdl.DestroyRenderer(display.sdl_renderer)
    }
    if display.sdl_window != nil {
        sdl.DestroyWindow(display.sdl_window)
    }
    sdl.Quit()
}

mpcStudioUpdate :: proc(display_ptr: rawptr) {
    display := cast(^MPCStudioDisplay)display_ptr
    eventcounter := 0
    for sdl.PollEvent(&display.event) {
        if display.event.type == sdl.EventType.QUIT {
            display.running = false
            return
        }
        eventcounter += 1
    }
    if eventcounter > 0 {
        fmt.printf("Processed %d SDL events\n", eventcounter)
    }
}

mpcStudioRender :: proc(display_ptr: rawptr) {
    display := cast(^MPCStudioDisplay)display_ptr
    // SDL Rendering
    sdl.SetRenderDrawColor(display.sdl_renderer, 0, 0, 0, 255)
    sdl.RenderClear(display.sdl_renderer)
    sdl.UpdateTexture(display.sdl_texture, nil, cairo.image_surface_get_data(display.surface),  cairo.image_surface_get_stride(display.surface))
    sdl.RenderTexture(display.sdl_renderer, display.sdl_texture, nil, &display.dRect)
    sdl.RenderPresent(display.sdl_renderer)
}


