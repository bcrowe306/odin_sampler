package graphics


import "../cairo"
import "../daw"
import "core:time"
import "core:fmt"
import sdl "vendor:sdl3"

SetupSurface :: proc(format: cairo.format_t, width, height: i32) -> (^cairo.surface_t, ^cairo.context_t) {
    surface := cairo.image_surface_create(format, width, height)
    cr := cairo.create(surface)
    cairo.SetupAntialiasing(cr)
    return surface, cr
}


Display :: struct {
    surface: ^cairo.surface_t,
    size: [2]i32,
    cr : ^cairo.context_t,
    format: cairo.format_t,
    backgound_color: cairo.Color,
    max_frames_per_second: f64,
    surface_render_user_data: rawptr,
    element_render_user_data: rawptr,
    running: bool,
    router : ^Router,
    events: [dynamic]sdl.Event,
    event : sdl.Event,
    daw : ^daw.DAW,
    
    // Methods
    clear: proc(display: rawptr),
    initialize: proc(display: rawptr, daw: ^daw.DAW),
    deInitialize: proc(display: rawptr),
    run: proc(display: rawptr),
    setMaxFramesPerSecond: proc(display: ^Display, fps: f64),

    // User override for custom drawing logic, called after widgets are drawn
    update : proc(display: rawptr),
    onUpdate : proc(display: rawptr),

    // User-defined render functions for more direct control over drawing, bypassing the display router page and widget rendering system. These can be used for special effects, performance optimizations, or to implement custom rendering.
    draw: proc(display: rawptr),

    // These can be used for more direct control over rendering. Cairo surfaces are flushed at this step. Use to draw to windows using SDL, raylib or similar, or to implement custom rendering.
    _render: proc(display: rawptr),
    onRender: proc(display: rawptr),

    // Render function to be called after every draw cycle. This will be given the whole display surface.
    surface_render: proc(surface: ^cairo.surface_t, x, y, width, height: i32, data: rawptr),

    // Render function to be called after ever draw cycle for each element. This will be given the element surface and bounds. Use this for more direct control over how elements are rendered, or to implement custom rendering logic .
    element_render: ElementRenderProc,

    onInitialize: proc(display: rawptr, daw: ^daw.DAW),
    onDeInitialize: proc(display: rawptr),
    onRun: proc(display: rawptr),

}

createDisplay :: proc(format: cairo.format_t, width, height: i32, background_color: cairo.Color = cairo.BLACK) -> ^Display {
    display := new(Display)
    configureDisplay(display, format, width, height, background_color)
    return display
}


configureDisplay :: proc(display_type: $T, format: cairo.format_t, width, height: i32, background_color: cairo.Color) {
    display := cast(^Display)display_type
    display.format = format
    display.size = {width, height}
    display.surface, display.cr = SetupSurface(format, width, height)
    display.backgound_color = background_color
    display.max_frames_per_second = 60.0
    display.router = createRouter()
    
    
    // Setup methods
    display.clear = displayClear
    display.draw = displayDraw
    display.initialize = initializeDisplay
    display.deInitialize = deInitializeDisplay
    display.run = displayRun
    display.update = displayUpdate
    display._render = displayRender
}


displayRun :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    display.running = true
    elapsed_duration := time.Duration(0)
    frame_duration := time.Duration(1.0 / display.max_frames_per_second * 1_000_000_000.0) // Convert seconds to nanoseconds
    current_tick := time.tick_now()
    for display.running {
        current_time := time.tick_now()
        elapsed_duration = time.tick_lap_time(&current_tick)
        if elapsed_duration >= frame_duration {

            // Input
            for sdl.PollEvent(&display.event) {
                append(&display.events, display.event)
                if display.event.type == sdl.EventType.QUIT {
                    display.running = false
                    return
                }
            }
            
            
            if display.update != nil {
                display->update()
            }

            // Draw
            display->clear()
            if display.draw != nil {
                display->draw()
            }

            // Render
            if display._render != nil {
                display->_render()
            }
            clear(&display.events)
        } else {
            time.sleep(frame_duration - elapsed_duration)
        }
    }
}

initializeDisplay :: proc(display_ptr: rawptr, daw: ^daw.DAW) {
    display := cast(^Display)display_ptr
    display.daw = daw
    // Initialize all widgets in the router pages
    for page_name, page_ptr in display.router.pages {
        page := cast(^PageElement)page_ptr
        page.daw = daw
    }

    // Call user-defined initialization logic if it exists
    if display.onInitialize != nil {
        display.onInitialize(display_ptr, daw)
    }
}

deInitializeDisplay :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    // Call user-defined deinitialization logic if it exists
    if display.onDeInitialize != nil {
        display.onDeInitialize(display_ptr)
    }
}


displayClear :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    cairo.set_source_rgba(display.cr, display.backgound_color.r, display.backgound_color.g, display.backgound_color.b, display.backgound_color.a)
    cairo.paint(display.cr)
}


displayDraw :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    current_page := display.router->getCurrentPage()
    if display.router.next_page.command != RouterStackCommand.None {
        if current_page != nil {
            fmt.printf("Clearing widgets on page switch from page: %s\n", current_page.name)
            current_page->clearPage(display.cr)
        }
    }
    
    page_changed := display.router->processPageSwitch()
    page := display.router->getCurrentPage()
    if page_changed {
        display->clear()
        page->invalidatePage()
    }
    
    if page != nil {
        page->drawPage(display.cr)
    }
    cairo.surface_flush(display.surface)

    // Call user-defined surface render function if it exists
    if display.surface_render != nil {
        display.surface_render(display.surface, 0, 0, display.size.x, display.size.y, display.surface_render_user_data)
    }
}

displayUpdate :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    // Update
    if display.onUpdate != nil {
        display->onUpdate()
    }
    page:= display.router->getCurrentPage()
    
    if page != nil {
        // TODO: Pass in SDL events to the page and its elements instead of nil
        page->_update(display.events[:])
    }
}

displayRender :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    page:= display.router->getCurrentPage()
    
    if display.element_render != nil {
        page:= display.router->getCurrentPage()
        if page != nil {
            page->renderPage(display.surface, display.element_render, display.element_render_user_data)
        }
    }

    if display.surface_render != nil {
        display.surface_render(display.surface, 0, 0, display.size.x, display.size.y, display.surface_render_user_data)
    }

    if display.onRender != nil {
        display->onRender()
    }
}