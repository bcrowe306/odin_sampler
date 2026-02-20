package graphics

import "core:math"
import "core:fmt"
import "core:encoding/uuid"
import "core:crypto"
import sdl "vendor:sdl3"
import "../cairo"  
import "../app"






ElementRenderProc :: proc(element: rawptr, surface: ^cairo.surface_t, user_data: rawptr)

ElementType :: enum {
    Base,
    Button,
    Slider,
    Knob,
    Page,
    Meter,
    Function,
    Pan,
    Text,
    Label,
}


Element :: struct {
    id: uuid.Identifier,
    type: ElementType,
    visible: bool,
    enabled: bool,
    changed: bool,
    selected: bool,
    bounds: cairo.rectangle_t,
    input_state: ^InputState,
    drag_threshold: f64, // Scale factor for drag input, can be used to adjust sensitivity of drag interactions
    children : [dynamic]rawptr, // Child elements for nesting

    setBounds: proc(element_ptr: rawptr, bounds: cairo.rectangle_t),
    setVisible: proc(element_ptr: rawptr, visible: bool),
    setEnabled: proc(element_ptr: rawptr, enabled: bool),
    setSelected: proc(element_ptr: rawptr, selected: bool),

    clear: proc(element: ^Element, cr: ^cairo.context_t),

    // Add child element to this element. Child elements will be updated, laid out, drawn, and rendered when the parent element is.
    addChild: proc(parent_ptr: rawptr, child_ptr: rawptr),

    // Remove child element from this element. Child elements will no longer be updated, laid out, drawn, or rendered when the parent element is.
    removeChild: proc(parent_ptr: rawptr, child_ptr: rawptr),

    // User overrides. Use this to update the element
    _update: proc(element_ptr: rawptr, events: []sdl.Event),
    onUpdate: proc(element_ptr: rawptr, events: []sdl.Event),

    // Clay layout proc
    _layout : proc(element_ptr: rawptr),
    onLayout: proc(element_ptr: rawptr),

    // Drawing proc. Use this to draw the element using the provided render command.
    _draw: proc(element_ptr: rawptr, cr: ^cairo.context_t),
    onDraw: proc(element_ptr: rawptr, cr: ^cairo.context_t),

    // Render proc. Use this to render the surface to various targets like a hardware display.
    _render: proc(element_ptr: rawptr),
    onRender: proc(element_ptr: rawptr),

    // Signals
    onPressed: ^app.Signal,
    onReleased: ^app.Signal,
    onClick: ^app.Signal,
    onDrag: ^app.Signal,

}

configureElement :: proc(el: ^Element, type: ElementType) {
    context.random_generator = crypto.random_generator()
    el.id = uuid.generate_v4()
    el.type = type
    el.changed = true
    el.visible = true
    el.enabled = true
    el.drag_threshold = 20.0
    el.input_state = createInputState()
    el.addChild = addChild
    el.removeChild = removeChild
    el._update = elementUpdate
    el._layout = elementLayout
    el._draw = elementDraw
    el.setBounds = elementSetBounds
    el.setVisible = elementSetVisible
    el.setEnabled = elementSetEnabled
    el.setSelected = elementSetSelected

    // Signals
    el.onPressed = app.createSignal()
    el.onReleased = app.createSignal()
    el.onClick = app.createSignal()
    el.onDrag = app.createSignal()
}

clearElement :: proc(element: ^Element, cr: ^cairo.context_t) {
    cairo.set_color(cr, cairo.BLACK)
    cairo.paint(cr)
}

addChild :: proc(parent_ptr: rawptr, child_ptr: rawptr) {
    parent := cast(^Element)parent_ptr
    child := cast(^Element)child_ptr
    append(&parent.children, child_ptr)
    parent.changed = true
}   

removeChild :: proc(parent_ptr: rawptr, child_ptr: rawptr) {
    parent := cast(^Element)parent_ptr
    child := cast(^Element)child_ptr
    for index in 0..<len(parent.children) {
        if parent.children[index] == child_ptr {
            ordered_remove(&parent.children, index)
            break
        }
    }
    parent.changed = true
}


elementUpdate :: proc(element_ptr: rawptr, events: []sdl.Event) {
    element := cast(^Element)element_ptr
    element.input_state->update(events, element_ptr)
    processDefaultElementEvents(element, events)
    if element.onUpdate != nil && element.enabled {
        element.onUpdate(element_ptr, events)
    }
    for child_ptr in element.children {
        child := cast(^Element)child_ptr
        child->_update(events)
    }
}

processDefaultElementEvents :: proc(element: ^Element, events: []sdl.Event) {
    element_processReleaseAndClick(element, events)
    element_processPressed(element, events)
    element_processDrag(element)
}

element_processReleaseAndClick :: proc(element: ^Element, events: []sdl.Event) {
    for event in events {
        if event.type == sdl.EventType.MOUSE_BUTTON_UP {
            for is_button_down, index in element.input_state.mouse_buttons{
                if index == int(event.button.button) - 1 && is_button_down {
                    app.signalEmit(element.onClick, index)
                }
            }
            if isInBoundsScaled(element.input_state.mouse_position.x, element.input_state.mouse_position.y, element.bounds, element.input_state.window_scale) {
                app.signalEmit(element.onReleased, int(event.button.button) - 1)
            }
        }
    }
}

element_processPressed :: proc(element: ^Element, events: []sdl.Event) {
    if element.input_state.isClicked(events, element, 0, 1.5) {
        for button_clicked, index in element.input_state.mouse_buttons {
            if button_clicked {
                app.signalEmit(element.onPressed, index)
            }
        }
    }
}

element_processDrag :: proc(element: ^Element) {
     if element.input_state->isMouseButtonDown(0) {
        mouse_drag := element.input_state->getDrag(0)
            
            if abs(f64(mouse_drag.y)) > element.drag_threshold {
                element.input_state.mouse_delta.y = 0
                multiplier := 1.0
                if mouse_drag.y < 0 {
                    multiplier = -1.0
                }
                app.signalEmit(element.onDrag, multiplier)
            }
    }
}


elementLayout :: proc(element_ptr: rawptr) {
    element := cast(^Element)element_ptr
    if element.onLayout != nil && element.visible {
        element.onLayout(element_ptr)
    }
    for child_ptr in element.children {
        child := cast(^Element)child_ptr
        child->_layout()
    }
}

elementDraw :: proc(element_ptr: rawptr, cr: ^cairo.context_t) {
    element := cast(^Element)element_ptr
    if element.onDraw != nil && element.visible {
        element.onDraw(element_ptr, cr)
    }
    for child_ptr in element.children {
        child := cast(^Element)child_ptr
        child->_draw(cr)
    }
}

elementSetBounds :: proc(element_ptr: rawptr, bounds: cairo.rectangle_t) {
    element := cast(^Element)element_ptr
    if element.bounds != bounds {
        element.bounds = bounds
        element.changed = true
    }
}

elementSetVisible :: proc(element_ptr: rawptr, visible: bool) {
    element := cast(^Element)element_ptr
    if element.visible != visible {
        element.visible = visible
        element.changed = true
    }
}

elementSetEnabled :: proc(element_ptr: rawptr, enabled: bool) {
    element := cast(^Element)element_ptr
    if element.enabled != enabled {
        element.enabled = enabled
        element.changed = true
    }
}

elementSetSelected :: proc(element_ptr: rawptr, selected: bool) {
    element := cast(^Element)element_ptr
    if selected != element.selected {
        element.selected = selected
        element.changed = true
    }
}

