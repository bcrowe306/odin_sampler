package cairo


import "core:fmt"
import "core:math"


FunctionWidget :: struct {
    using widget: Widget,
    color: Color,
    label: string,
    font_size: f64,
    selected: bool,
    padding_x: f64,
    padding_y: f64,
    radius: f64,
}

createFunctionWidget :: proc(bounds: rectangle_t, label: string = "Function", font_size: f64 = 9) -> ^FunctionWidget {
    func_widget := new(FunctionWidget)
    configureNewWidget(cast(^Widget)func_widget, bounds)
    func_widget.color = WHITE
    func_widget.selected = true
    func_widget.draw = drawFunctionWidget
    func_widget.label = label
    func_widget.font_size = font_size
    func_widget.padding_x = 3
    func_widget.padding_y = 0
    func_widget.radius = 4
    return func_widget
}

drawFunctionWidget :: proc(widget_ptr: rawptr) {

    widget := cast(^FunctionWidget)widget_ptr
    cr := widget.cr
    text_color := WHITE
    if widget.selected {
        text_color = BLACK
    }
    draw_top_rounded_rectangle(cr, widget.padding_x, widget.padding_y, widget.bounds.width - (widget.padding_x * 2), widget.bounds.height - (widget.padding_y * 2), widget.radius, widget.selected, widget.color)
    // draw_text(cr, widget.label, widget.padding_x, 5, widget.font_size, text_color)
    draw_text_centered(cr, widget.label, rectangle_t{0, 0, widget.bounds.width, widget.bounds.height}, widget.font_size, text_color)
}