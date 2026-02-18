package cairo

import "core:c"
import "core:math"
import "core:fmt"

KnobWidget :: struct {
    using widget: Widget,
    color: Color,
    min: f64,
    max: f64,
    value: f64,
    angle_range: f64,
    angle_start: f64,
    thickness: f64,
    centered: bool,
    label: string,
    value_string: string,
    setValue: proc(widget: ^KnobWidget, value: f64, value_string: string = ""),
    valueDisplayFunction : proc(value: f64) -> cstring,
    font_size: f64,
   
}


createKnobWidget :: proc(bounds: rectangle_t, label: string = "", font_size: f64 = 9.5) -> ^KnobWidget {
    knob_widget := new(KnobWidget)
    configureNewWidget(cast(^Widget)knob_widget, bounds)
    knob_widget.color = WHITE
    knob_widget.min = 0.0
    knob_widget.max = 1.0
    knob_widget.value = 0.0
    knob_widget.angle_range = 270
    knob_widget.angle_start = 120.0
    knob_widget.thickness = 5.0
    knob_widget.centered = true
    knob_widget.draw = drawKnobWidget
    knob_widget.setValue = setValue
    knob_widget.changed = true
    knob_widget.label = label
    knob_widget.font_size = font_size
    knob_widget.value_string = ""
    knob_widget.valueDisplayFunction = nil

    return knob_widget
}

drawKnobWidget :: proc(widget_ptr: rawptr) {
    widget := cast(^KnobWidget)widget_ptr
    cr := widget.cr

    text_height := widget.font_size + 1
    label_padding_left := 10.0
    // Draw Label
    select_font_face(cr, "Sans", font_slant_t.NORMAL, font_weight_t.NORMAL)
    set_font_size(cr, widget.font_size)
    set_source_rgba(cr, widget.color.r, widget.color.g, widget.color.b, widget.color.a)
    extents: text_extents_t
    text_extents(cr, fmt.ctprint(widget.label), &extents)
    move_to(cr, label_padding_left, text_height)
    show_text(cr, fmt.ctprint(widget.label))
    



   
    center_x := widget.bounds.width / 2;
    center_y := (widget.bounds.height - text_height) / 2 + text_height; // Adjust center_y to account for label height
    radius := (widget.bounds.height - widget.thickness - text_height ) / 2 - 4; // Adjust radius to fit within the widget
  
    // sangle := math.to_radians(90 + ((360.0 - widget.angle_range) / 2.0));
    sangle := math.to_radians(f64(90))
    eangle := math.to_radians(90 + widget.angle_range * widget.value + 2);
    move_to(cr, center_x, center_y + radius)
    
    set_line_width(cr, widget.thickness);
    set_source_rgba(cr, 1.0, 1.0, 1.0, 1.0); // Set knob color
    arc(cr, center_x, center_y, radius, sangle, eangle);
    stroke(cr);

    move_to(cr, center_x + 2, center_y + text_height + radius / 2 - 3);
    select_font_face(cr, "Sans", font_slant_t.NORMAL, font_weight_t.NORMAL)
    set_font_size(cr, widget.font_size)
    set_source_rgba(cr, widget.color.r, widget.color.g, widget.color.b, widget.color.a)

    valueDisplay : cstring
    if widget.valueDisplayFunction != nil {
        valueDisplay = widget.valueDisplayFunction(widget.value)
    } else {
        if widget.value_string != "" {
            valueDisplay = fmt.ctprint(fmt.ctprintf("%s", widget.value_string))
        } else {
            valueDisplay = fmt.ctprint(fmt.ctprintf("%.2f", widget.value))
        }
    }
    extents2: text_extents_t
    text_extents(cr, valueDisplay, &extents2)
    show_text(cr, valueDisplay)
}

setValue :: proc(widget: ^KnobWidget, value: f64, value_string: string = "") {
    new_value := math.clamp(value, widget.min, widget.max);
    if new_value != widget.value {
        widget.value = new_value
        widget.value_string = value_string
        widget.changed = true
    }
}

setLabel :: proc(widget: ^KnobWidget, label: string) {
    if label != widget.label {
        widget.label = label
        widget.changed = true
    }
}

setValueString :: proc(widget: ^KnobWidget, value_string: string) {
    if value_string != widget.value_string {
        widget.value_string = value_string
        widget.changed = true
    }
}
