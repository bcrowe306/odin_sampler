package cairo


RectangleWidget :: struct {
    using widget: Widget,
    color: Color,
    rectangle: rectangle_t,
    setPosition: proc(widget: ^RectangleWidget, x, y: i32),
    setSize: proc(widget: ^RectangleWidget, width, height: i32),
    setColor: proc(widget: ^RectangleWidget, color: Color),
    setSizePercentage: proc(widget: ^RectangleWidget, widthPercent: f64 = 1.0, heightPercent: f64 = 1.0),
}

createRectangleWidget :: proc(bounds: rectangle_t, color: Color, surface: ^surface_t) -> ^RectangleWidget {
    rect_widget := new(RectangleWidget)
    configureNewWidget(cast(^Widget)rect_widget, bounds)
    rect_widget.color = color
    rect_widget.draw = drawRectangle
    rect_widget.setPosition = rectangleWidgetSetPosition
    rect_widget.setSize = rectangleWidgetSetSize
    rect_widget.setColor = rectangleWidgetSetColor
    rect_widget.setSizePercentage = rectangleSetSizePercentage
    return rect_widget
}

rectangleWidgetSetPosition :: proc(widget: ^RectangleWidget, x, y: i32) {
    widget.rectangle.x = f64(x)
    widget.rectangle.y = f64(y)
    widget.widget.changed = true
}

rectangleWidgetSetSize :: proc(widget: ^RectangleWidget, width, height: i32) {
    widget.rectangle.width = f64(width)
    widget.rectangle.height = f64(height)
    widget.widget.changed = true
}

rectangleWidgetSetColor :: proc(widget: ^RectangleWidget, color: Color) {
    widget.color = color
    widget.widget.changed = true
}

rectangleSetSizePercentage :: proc(widget: ^RectangleWidget, widthPercent: f64 = 1.0, heightPercent: f64 = 1.0) {
    widget.rectangle.width = widget.bounds.width * widthPercent
    widget.rectangle.height = widget.bounds.height * heightPercent
    widget.widget.changed = true
}

drawRectangle :: proc(widget_ptr: rawptr) {
    widget := cast(^RectangleWidget)widget_ptr
    cr := widget.cr
    set_source_rgba(cr, widget.color.r, widget.color.g, widget.color.b, widget.color.a)
    rectangle(cr, widget.rectangle.x, widget.rectangle.y, widget.rectangle.width, widget.rectangle.height)
    fill(cr)
}
