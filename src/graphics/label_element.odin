package graphics

import "core:fmt"

import "../cairo"
import sdl "vendor:sdl3"

LabelElement :: struct {
    using element: Element,
    label: string,
    bg_color: cairo.Color,
    fg_color: cairo.Color,
    font_size: f64,
    radius: f64,

    // Methods
    setText: proc(element_ptr: rawptr, text: string),
    
}


createLabelElement :: proc(label: string, selected: bool = false) -> ^LabelElement {
    element := new(LabelElement)
    configureElement(element, ElementType.Label)
    element.label = label
    element.selected = selected
    element.onDraw = drawLabelElement
    element.bg_color = {0,0,0,1.0}
    element.fg_color = cairo.WHITE
    element.font_size = 9.5
    element.radius = 5
    element.onUpdate = labelOnUpdate
    element.setText = labelSetText
    return element
}

drawLabelElement :: proc(element_ptr: rawptr, cr: ^cairo.context_t) {
    element := cast(^LabelElement)element_ptr

    text_color := element.fg_color
    fill_color := element.bg_color

    cairo.draw_text_centered(cr, element.label, element.bounds, element.font_size, text_color)
    if element.selected {
        cairo.draw_horizontal_line(cr, element.bounds.y + element.bounds.height - 2, element.bounds.x, element.bounds.x + element.bounds.width, 1.0, text_color)
    }
   
}

labelOnUpdate :: proc(element_ptr: rawptr, events: []sdl.Event) {
    element := cast(^LabelElement)element_ptr

    for event in events {
        if isMouseClickWithinElement(event, element, 0) {
            element.selected = !element.selected
            element.changed = true
            fmt.printf("Label clicked, selected: %v\n", element.selected)
        }
    }
}

labelSetText :: proc(element_ptr: rawptr, text: string) {
    element := cast(^LabelElement)element_ptr
    element.label = text
    element.changed = true
}
