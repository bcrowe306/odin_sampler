package graphics

import "core:fmt"

import "../cairo"
import sdl "vendor:sdl3"

ButtonElement :: struct {
    using element: Element,
    label: string,
    label_false: string,
    value: bool,
    index: int,
    bg_color: cairo.Color,
    fg_color: cairo.Color,
    font_size: f64,
    radius: f64,
    setValue: proc(widget: ^ButtonElement, value: bool),
    getLabel: proc(widget: ^ButtonElement) -> string,
    
}


createButtonElement :: proc(index: int, label: string, selected: bool = false) -> ^ButtonElement {
    element := new(ButtonElement)
    configureElement(element, ElementType.Function)
    element.type = ElementType.Button
    element.index = index
    element.label = label
    element.selected = selected
    element.onDraw = drawButtonElement
    element.bg_color = {0,0,0,1.0}
    element.fg_color = cairo.WHITE
    element.font_size = 9
    element.radius = 3.5
    element.onUpdate = onUpdateButtonElement
    element.value = false
    element.label_false = ""
    element.setValue = setButtonElementValue
    element.getLabel = getButtonLabel
    return element
}

drawButtonElement :: proc(element_ptr: rawptr, cr: ^cairo.context_t) {
    element := cast(^ButtonElement)element_ptr

    text_color := element.fg_color
    fill_color := element.bg_color
    if element.value {
        text_color = element.bg_color
    }
    cairo.draw_rectangle_bounds(cr, element.bounds, element.value, element.fg_color)
    // draw_text(cr, element.label, element.padding_x, 5, element.font_size, text_color)
    cairo.draw_text_centered(cr, element->getLabel(), element.bounds, element.font_size, text_color)
    if element.selected {
        line_x_padding : f64 = element.bounds.width * .15
        cairo.draw_horizontal_line(cr, element.bounds.y + element.bounds.height - 2, element.bounds.x + line_x_padding, element.bounds.x + element.bounds.width - line_x_padding, 1.0, text_color)
    }
   
}

onUpdateButtonElement :: proc(element_ptr: rawptr, events: []sdl.Event) {
    element := cast(^ButtonElement)element_ptr
   
    if element.input_state.isClicked(events, element, 0, 1.5) {
        element->setSelected(!element.selected)
    }
    if element.input_state.isClicked(events, element, 2, 1.5) {
        element->setValue(!element.value)
    }

}

getButtonLabel :: proc(element: ^ButtonElement) -> string {
    if element.value {
        return element.label
    }
    else {
        if element.label_false == "" {
            return element.label
        }
        return element.label_false
    }
}

setButtonElementValue :: proc (element: ^ButtonElement, value: bool) {
    if element.value != value {
        element.value = value
        element.changed = true
    }
}