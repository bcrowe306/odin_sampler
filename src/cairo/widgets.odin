package cairo

import "../daw"
import sdl "vendor:sdl3"

Color :: [4]f64
WHITE : Color = {1.0, 1.0, 1.0, 1.0}
BLACK : Color = {0.0, 0.0, 0.0, 1.0}
RED : Color = {1.0, 0.0, 0.0, 1.0}
GREEN : Color = {0.0, 1.0, 0.0, 1.0}
BLUE : Color = {0.0, 0.0, 1.0, 1.0}

// display render function signature
displayRenderFunc :: proc(surface: ^surface_t, xPos, yPos, width, height: i32, data: rawptr)

SetupAntialiasing :: proc(cr: ^context_t) {
    set_antialias(cr, antialias_t.NONE)
    font_options := font_options_create()
    font_options_set_antialias(font_options, antialias_t.NONE)
    set_font_options(cr, font_options)
    font_options_destroy(font_options)
}


SetupSurface :: proc(format: format_t, width, height: i32) -> (^surface_t, ^context_t) {
    surface := image_surface_create(format, width, height)
    cr := create(surface)
    SetupAntialiasing(cr)
    return surface, cr
}


Widget :: struct {
    bounds: rectangle_t,
    visible: bool,
    enabled: bool,
    changed: bool,
    cr: ^context_t,
    main_surface: ^surface_t,
    surface: ^surface_t,
    background_color: Color,
    daw: ^daw.DAW,

    // Methods
    update: proc(widget_ptr: rawptr, events: ^sdl.Event = nil),
    draw: proc(widget_ptr: rawptr),
    clear: proc(widget: ^Widget),
    render: proc(widget: rawptr),
    render_user_data: rawptr,
    initialize: proc(widget: rawptr, surface: ^surface_t, daw: ^daw.DAW, render: proc(widget: rawptr) = nil, render_user_data: rawptr = nil),
}

initializeWidget :: proc(widget_ptr: rawptr, surface: ^surface_t, daw: ^daw.DAW, render: proc(widget: rawptr) = nil, render_user_data: rawptr = nil) {
    widget := cast(^Widget)widget_ptr
    widget.changed = true
    widget.main_surface = surface
    widget.surface = surface_create_for_rectangle(widget.main_surface, f64(widget.bounds.x), f64(widget.bounds.y), f64(widget.bounds.width), f64(widget.bounds.height))
    widget.cr = create(widget.surface)
    SetupAntialiasing(widget.cr)
    widget.daw = daw
    if render != nil {
        widget.render = render
        widget.render_user_data = render_user_data
    }
}

widgetClear :: proc(widget: ^Widget) {
    set_color(widget.cr, widget.background_color)
    paint(widget.cr)
}

configureNewWidget :: proc(widget: ^Widget, bounds: rectangle_t, background_color: Color = BLACK) {
    widget.bounds = bounds
    widget.visible = true
    widget.enabled = true
    widget.changed = true
    widget.background_color = background_color
    widget.clear = widgetClear
    widget.initialize = initializeWidget
    widget.update = widgetUpdate
    widget.draw = draw
}


widgetUpdate :: proc(widget_ptr: rawptr, events: ^sdl.Event = nil) {
     widget := cast(^Widget)widget_ptr
     // Base widget update function, can be overridden by specific widget types.
     // For example, you could add logic here to check if the widget's state has changed and set widget.changed = true if it has.
    
}

// Base widget draw function, can be overridden by specific widget types.
draw :: proc(widget_ptr: rawptr) {
    widget := cast(^Widget)widget_ptr
    widget.changed = false
}


