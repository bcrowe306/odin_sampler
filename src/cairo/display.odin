package cairo

import "core:fmt"

import "core:time"
import "../daw"



Display :: struct {
    surface: ^surface_t,
    size: [2]i32,
    cr : ^context_t,
    format: format_t,
    widgets: [dynamic]rawptr,
    backgound_color: Color,
    max_frames_per_second: f64,
    surface_render_user_data: rawptr,
    widget_render_user_data: rawptr,
    running: bool,
    router : ^Router,
    daw : ^daw.DAW,
    
    // Methods
    addWidget: proc(display_ptr: rawptr, widget: rawptr),
    removeWidget: proc(display_ptr: rawptr, widget: rawptr),
    clear: proc(display: rawptr),
    initialize: proc(display: rawptr, daw: ^daw.DAW),
    deInitialize: proc(display: rawptr),
    run: proc(display: rawptr),
    setMaxFramesPerSecond: proc(display: ^Display, fps: f64),

    // User override for custom drawing logic, called after widgets are drawn
    update : proc(display: rawptr),

    // User-defined render functions for more direct control over drawing, bypassing the display router page and widget rendering system. These can be used for special effects, performance optimizations, or to implement custom rendering logic that doesn't fit into the standard widget/page system.
    draw: proc(display: rawptr),

    // These can be used for more direct control over rendering. Cairo surfaces are flushed at this step. Use to draw to windows using SDL, raylib or similar, or to implement custom rendering logic that doesn't fit into the standard widget/page system.
    render: proc(display: rawptr),
    surface_render: proc(surface: ^surface_t, x, y, width, height: i32, data: rawptr),
    widget_render: proc(widget: rawptr),
    onInitialize: proc(display: rawptr),
    onDeInitialize: proc(display: rawptr),
    onRun: proc(display: rawptr),

}

createDisplay :: proc(format: format_t, width, height: i32, background_color: Color = BLACK) -> ^Display {
    display := new(Display)
    configureDisplay(display, format, width, height, background_color)
    return display
}


configureDisplay :: proc(display_type: $T, format: format_t, width, height: i32, background_color: Color) {
    display := cast(^Display)display_type
    display.format = format
    display.size = {width, height}
    display.surface, display.cr = SetupSurface(format, width, height)
    display.backgound_color = background_color
    display.max_frames_per_second = 60.0
    display.router = createRouter()
    
    
    // Setup methods
    display.addWidget = displayAddWidget
    display.removeWidget = displayRemoveWidget
    display.clear = displayClear
    display.draw = displayDraw
    display.initialize = initializeDisplay
    display.deInitialize = deInitializeDisplay
    display.run = displayRun

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

            
            if display.update != nil {
                display->update()
            }

            // Draw
            if display.draw != nil {
                display->draw()
            }

            // Render
            if display.render != nil {
                display->render()
            }
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
        page := cast(^PageWidget)page_ptr
        page.initialize(page_ptr, display.surface, display.daw, display.widget_render, display.widget_render_user_data)
    }

    
    // Call user-defined initialization logic if it exists
    if display.onInitialize != nil {
        display.onInitialize(display_ptr)
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
    set_color(display.cr, display.backgound_color)
    paint(display.cr)
}

displayAddWidget :: proc(display_ptr: rawptr, widget: rawptr) {
    display := cast(^Display)display_ptr
    append(&display.widgets, widget)
}

displayRemoveWidget :: proc(display_ptr: rawptr, widget: rawptr) {
    display := cast(^Display)display_ptr
    for i in 0..<len(display.widgets) {
        if display.widgets[i] == widget {
            ordered_remove(&display.widgets, i)
            break
        }
    }
}

displayDraw :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    current_page := display.router->getCurrentPage()
    if display.router.next_page.command != RouterStackCommand.None {
        if current_page != nil {
            fmt.printf("Clearing widgets on page switch from page: %s\n", current_page.name)
            current_page->clearWidgets()
        }
    }
    
    page_changed := display.router->processPageSwitch()
    page := display.router->getCurrentPage()
    if page_changed {
        display->clear()
        invalidatePage(page)
    }
    
    if page != nil {
        page->draw()
    }
    surface_flush(display.surface)

    // Call user-defined surface render function if it exists
    if display.surface_render != nil {
        display.surface_render(display.surface, 0, 0, display.size.x, display.size.y, display.surface_render_user_data)
    }
}

displayUpdate :: proc(display_ptr: rawptr) {
    display := cast(^Display)display_ptr
    // Update
    page:= display.router->getCurrentPage()
    if page != nil {
        page->update()
    }
}

