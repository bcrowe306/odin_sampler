package graphics

import "core:math"
import "core:fmt"

import "../cairo"
import sdl "vendor:sdl3"

MeterElement :: struct {
    using element: Element,
    l_value: f32,
    r_value: f32,
    value: f32,
    min_decibel: f32,
    max_decibel: f32,
    min_fader: f32,
    max_fader: f32,
    fg_color: cairo.Color,
    font_size: f64,
    setMeters: proc(widget: ^MeterElement, l_value: f32, r_value: f32),
    setMeter: proc(widget: ^MeterElement, value: f32),
    setFaderValue: proc(widget: ^MeterElement, value: f32),
    getLabelText: proc(widget: ^MeterElement) -> cstring,
    
}

createMeterElement :: proc(value: f32, min_decibel: f32 = -60.0, max_decibel: f32 = 0.0) -> ^MeterElement {
    element := new(MeterElement)
    configureElement(element, ElementType.Meter)
    element.type = ElementType.Meter
    element.l_value = -6.0
    element.r_value = -12.0
    element.value = value
    element.min_decibel = min_decibel
    element.max_decibel = max_decibel
    element.min_fader = -60.0
    element.max_fader = 6.0
    element.font_size = 9.5
    element.fg_color = cairo.WHITE
    
    // Methods
    element.onDraw = drawMeterElement
    element.setMeters = setMeters
    element.setMeter = setMeter
    element.setFaderValue = setFaderValue
    element.getLabelText = getLabelText
    element.onUpdate = onUpdateMeter

    return element
}

drawMeterElement :: proc (element_ptr: rawptr, cr: ^cairo.context_t) {
    element := cast(^MeterElement)element_ptr
    decibel_range :f64= f64(element.max_decibel - element.min_decibel)
    fader_range :f64 = f64(element.max_fader - element.min_fader)
    gap :f64 = 4
    x_padding: f64 = 4
    y_padding: f64 = 4
    sections :f64 = 3

    // Label
    exts : cairo.text_extents_t
    fader_volume_label := element->getLabelText()
    cairo.text_extents(cr, fader_volume_label, &exts)

    // Calculate meter dimensions
    meter_width :f64 = (element.bounds.width - (gap * (sections - 1) + x_padding)) / sections 
    max_meter_height :f64 = element.bounds.height - (y_padding * 2) - exts.height
    left_meter_height := (f64(element.l_value) - f64(element.min_decibel)) / decibel_range * max_meter_height
    right_meter_height := (f64(element.r_value) - f64(element.min_decibel)) / decibel_range * max_meter_height
    
    left_meter_y := element.bounds.y + max_meter_height - left_meter_height
    right_meter_y := element.bounds.y + max_meter_height - right_meter_height
    
    left_meter_x := element.bounds.x + x_padding
    right_meter_x := element.bounds.x + x_padding + meter_width + gap
    
    fader_height := (f64(element.value) - f64(element.min_fader)) / fader_range * max_meter_height - (exts.height / 2)  
    fader_x := element.bounds.x + x_padding + (meter_width + gap) * 2
    fader_y := element.bounds.y + max_meter_height - fader_height
    fader_line_width := 1.0
    fader_x_end := fader_x + meter_width - fader_line_width - x_padding
    

    label_y := element.bounds.y + max_meter_height + y_padding
    label_x := element.bounds.x
    label_height : = element.bounds.height - max_meter_height - (y_padding * 2)
    label_width := element.bounds.width

    label_bounds := cairo.rectangle_t{label_x, label_y, label_width, label_height}

    // Draw left meter
    cairo.draw_rectangle(cr, left_meter_x, left_meter_y, meter_width, left_meter_height, true, element.fg_color)
    // Draw right meter
    cairo.draw_rectangle(cr, right_meter_x, right_meter_y, meter_width, right_meter_height, true, element.fg_color)
    // Draw fader    cairo.draw_rectangle(cr, fader_x, fader_y, meter_width, 2, element.fg_color)
    cairo.draw_horizontal_line(cr, fader_y, fader_x, fader_x_end, fader_line_width, element.fg_color)
    cairo.draw_vertical_line(cr, fader_x_end, fader_y, fader_y + fader_height, fader_line_width, element.fg_color)
    


    // Draw label centered
    cairo.draw_text_centered(cr, fmt.tprintf("%s", element->getLabelText()), label_bounds, element.font_size, element.fg_color)

    if element.selected {
        cairo.draw_rectangle(cr, element.bounds.x + 1, element.bounds.y + 1, element.bounds.width - 2, element.bounds.height - 2, false, element.fg_color)
    }
}

getLabelText :: proc(widget: ^MeterElement) -> cstring {
    return fmt.ctprintf("%.2f dB", widget.value)
}

setMeters :: proc(element: ^MeterElement, l_value: f32, r_value: f32) {
    if element.l_value != l_value || element.r_value != r_value {
        element.l_value = l_value
        element.r_value = r_value
        element.changed = true
    }
}

setMeter :: proc(element: ^MeterElement, value: f32) {
    if element.l_value != value || element.r_value != value {
        element.l_value = value
        element.r_value = value
        element.changed = true
    }
}

setFaderValue :: proc(element: ^MeterElement, value: f32) {
    if element.value != value {
        v := math.clamp(value, element.min_fader, element.max_fader)
        element.value = v
        element.changed = true
    }
}

onUpdateMeter :: proc(element_ptr: rawptr, events: []sdl.Event) {
    element := cast(^MeterElement)element_ptr
    if element.input_state.isClicked(events, element, 0, 1.5 ) {
        element->setSelected(!element.selected)
    }
    if element.input_state->isMouseButtonDown(0) {
        mouse_drag := element.input_state->getDrag(0)
            fader_range :f32 = element.max_fader - element.min_fader
            value_change := -mouse_drag.y / f32(element.bounds.height) * fader_range
            element->setFaderValue(element.value + value_change)
    }
}

processDrag :: proc(element_ptr: rawptr) {
    element := cast(^MeterElement)element_ptr
     if element.input_state->isMouseButtonDown(0) {
        mouse_drag := element.input_state->getDrag(0)
            fader_range :f32 = element.max_fader - element.min_fader
            value_change := -mouse_drag.y / f32(element.bounds.height) * fader_range
            element->setFaderValue(element.value + value_change)
    }
}