package graphics


import "../cairo"
import "core:fmt"
import "core:math"
import sdl "vendor:sdl3"

KnobElement :: struct {
    using element: Element,
    label: string,
    value: f64,
    min: f64,
    max: f64,
    default: f64,
    value_string: string,
    bg_color: cairo.Color,
    fg_color: cairo.Color,
    font_size: f64,
    angle_range: f64,
    angle_start: f64,
    thickness: f64,
    setValue: proc(widget: ^KnobElement, value: f64, value_string: string = ""),
    setLabel: proc(widget: ^KnobElement, label: string),
    setValueString: proc(widget: ^KnobElement, value_string: string),
    valueDisplayFunction : proc(value: f64) -> cstring,
    
}

createKnobElement :: proc(label: string, default: f64 = 0.5, min: f64 = 0.0, max: f64 = 1.0, font_size: f64 = 9.5) -> ^KnobElement {
    element := new(KnobElement)
    configureElement(element, ElementType.Knob)
    element.type = ElementType.Knob
    element.label = label
    element.value = default
    element.min = min
    element.max = max
    element.default = default
    element.angle_range = 270
    element.angle_start = 120.0
    element.thickness = 6
    element.bg_color = {0,0,0,1.0}
    element.fg_color = cairo.WHITE
    element.changed = true
    element.font_size = font_size
    element.value_string = ""
    element.selected = false
    
    // Methods
    element.valueDisplayFunction = nil
    element.onDraw = drawKnobElement
    element.onUpdate = onUpdateKnob
    element.setValue = setValue
    element.setLabel = setLabel
    element.setValueString = setValueString

    return element
}

drawKnobElement :: proc(element: rawptr, cr: ^cairo.context_t) {
    element := cast(^KnobElement)element
    using cairo

    text_height := element.font_size + 1
    label_padding_left := 10.0
    x := element.bounds.x
    y := element.bounds.y
    width := element.bounds.width
    height := element.bounds.height
    // Draw Label
    select_font_face(cr, "Sans", font_slant_t.NORMAL, font_weight_t.NORMAL)
    set_font_size(cr, element.font_size)
    set_source_rgba(cr, element.fg_color.r, element.fg_color.g, element.fg_color.b, element.fg_color.a)
    extents: text_extents_t
    text_extents(cr, fmt.ctprint(element.label), &extents)
    move_to(cr, x +label_padding_left, y + text_height)
    show_text(cr, fmt.ctprint(element.label))
    



   
    center_x := x + width / 2;
    center_y := y + (height - text_height) / 2 + text_height; // Adjust center_y to account for label height
    radius := (height - element.thickness - text_height ) / 2 - 4; // Adjust radius to fit within the widget
  
    // sangle := math.to_radians(90 + ((360.0 - widget.angle_range) / 2.0));
    sangle := math.to_radians(f64(90))
    eangle := math.to_radians(90 + element.angle_range * element.value + 2);
    move_to(cr, center_x, center_y + radius)
    
    set_line_width(cr, element.thickness);
    set_source_rgba(cr, 1.0, 1.0, 1.0, 1.0); // Set knob color
    arc(cr, center_x, center_y, radius, sangle, eangle);
    stroke(cr);

    move_to(cr, center_x + 2, center_y + text_height + radius / 2 - 3);
    select_font_face(cr, "Sans", font_slant_t.NORMAL, font_weight_t.NORMAL)
    set_font_size(cr, element.font_size)
    set_source_rgba(cr, element.fg_color.r, element.fg_color.g, element.fg_color.b, element.fg_color.a)

    valueDisplay : cstring
    if element.valueDisplayFunction != nil {
        valueDisplay = element.valueDisplayFunction(element.value)
    } else {
        if element.value_string != "" {
            valueDisplay = fmt.ctprint(fmt.ctprintf("%s", element.value_string))
        } else {
            valueDisplay = fmt.ctprint(fmt.ctprintf("%.2f", element.value))
        }
    }
    extents2: text_extents_t
    text_extents(cr, valueDisplay, &extents2)
    show_text(cr, valueDisplay)

    if element.selected {
        cairo.draw_rectangle(cr, x + 1, y + 1, width - 2, height - 2, false, element.fg_color)
    }
}


setValue :: proc(element: ^KnobElement, value: f64, value_string: string = "") {
    new_value := math.clamp(value, element.min, element.max);
    if new_value != element.value {
        element.value = new_value
        element.value_string = value_string
        element.changed = true
    }
}

setLabel :: proc(element: ^KnobElement, label: string) {
    if label != element.label {
        element.label = label
        element.changed = true
    }
}

setValueString :: proc(element: ^KnobElement, value_string: string) {
    if value_string != element.value_string {
        element.value_string = value_string
        element.changed = true
    }
}



onUpdateKnob :: proc(element_ptr: rawptr, events: []sdl.Event) {
    element := cast(^KnobElement)element_ptr
    if element.input_state.isClicked(events, element, 0, 1.5 ) {
        element->setSelected(!element.selected)
    }
    if element.input_state->isMouseButtonDown(0) {
        mouse_drag := element.input_state->getDrag(0)
        fmt.printfln("Mouse Drag: %v", mouse_drag)
        if abs(mouse_drag.y) > 0.5 {
            if mouse_drag.y > 0 {
                element->setValue(element.value - 0.01)
            } else if mouse_drag.y < 0 {
                element->setValue(element.value + 0.01)
            }
        }
        
    }
}