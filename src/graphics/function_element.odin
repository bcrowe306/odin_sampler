package graphics

import "core:fmt"

import "../cairo"
import sdl "vendor:sdl3"

FunctionElement :: struct {
    using element: Element,
    label: string,
    index: int,
    bg_color: cairo.Color,
    fg_color: cairo.Color,
    font_size: f64,
    radius: f64,
    
}


createFunctionElement :: proc(index: int, label: string, selected: bool = false) -> ^FunctionElement {
    element := new(FunctionElement)
    configureElement(element, ElementType.Function)
    element.type = ElementType.Function
    element.index = index
    element.label = label
    element.selected = selected
    element.onDraw = drawFunctionElement
    element.bg_color = {0,0,0,1.0}
    element.fg_color = cairo.WHITE
    element.font_size = 9
    element.radius = 3.5
    element.onUpdate = onUpdate
    return element
}

drawFunctionElement :: proc(element_ptr: rawptr, cr: ^cairo.context_t) {
    element := cast(^FunctionElement)element_ptr

    text_color := element.fg_color
    fill_color := element.bg_color
    if element.selected {
        text_color = element.bg_color
    }
    cairo.draw_top_rounded_rectangle(cr, element.bounds.x, element.bounds.y, element.bounds.width, element.bounds.height, element.radius, element.selected, element.fg_color)
    // draw_text(cr, element.label, element.padding_x, 5, element.font_size, text_color)
    cairo.draw_text_centered(cr, element.label, element.bounds, element.font_size, text_color)
   
}

onUpdate :: proc(element_ptr: rawptr, events: []sdl.Event) {
    element := cast(^FunctionElement)element_ptr

    for event in events {
        if isMouseClickWithinElement(event, element, 0) {
            element.selected = !element.selected
            element.changed = true
            fmt.printf("Function %d clicked, selected: %v\n", element.index + 1, element.selected)
        }
    }
}