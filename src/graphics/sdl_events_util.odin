package graphics

import "core:fmt"
import sdl "vendor:sdl3"
import cairo "../cairo"

// Event helper to detect sdl mouse click within element bounds
isMouseClickWithinElement :: proc(event: sdl.Event, element: ^Element, button_index: u8, scale: f32 = 1.5) -> bool {
    if event.type == sdl.EventType.MOUSE_BUTTON_DOWN {
        
        mouse_x := event.button.x / scale
        mouse_y := event.button.y / scale
        return isInBounds(mouse_x, mouse_y, element.bounds) && event.button.button - 1 == button_index
    }
    return false
}

// Post scaled. Use for detecting clicks within elements after scaling has been accounted for and applied.
isInBounds :: proc(x: f32, y: f32, bounds: cairo.rectangle_t) -> bool {
    if x >= f32(bounds.x) && x <= f32(bounds.x + bounds.width) &&
       y >= f32(bounds.y) && y <= f32(bounds.y + bounds.height) {
        return true
    }
    return false
}

// Detect if mouse is hovering over element
isMouseHoveringElement :: proc(event: sdl.Event, element: ^Element, scale: f32 = 1.5) -> bool {
    if event.type == sdl.EventType.MOUSE_MOTION {
        mouse_x := event.motion.x / scale
        mouse_y := event.motion.y / scale
        if isInBounds(mouse_x, mouse_y, element.bounds) {
            return true
        }
    }
    return false
}


InputState :: struct {
    mouse_position: [2]f32,
    window_scale: f32,
    mouse_delta: [2]f32,
    mouse_buttons: [5]bool, // Left, Middle, Right, Extra1, Extra2
    update: proc(state: ^InputState, events: []sdl.Event, element_ptr: rawptr),
    keys_pressed: map[string]bool,
    isMouseButtonDown: proc(state: ^InputState, button: u8) -> bool,
    getDrag : proc(state: ^InputState, button: u8) -> [2]f32,
    isClicked : proc(events: []sdl.Event, element: ^Element, button_index: u8, scale: f32) -> bool,
}

createInputState :: proc() -> ^InputState {
    state := new(InputState)
    state.window_scale = 1.5
    state.mouse_position = {0, 0}
    state.mouse_delta = {0, 0}
    state.mouse_buttons = [5]bool{false, false, false, false, false}
    state.keys_pressed = make(map[string]bool)
    state.update = updateInputState
    state.isMouseButtonDown = isMouseButtonDown
    state.getDrag = getDrag
    state.isClicked = isMouseClicked
    return state
}

updateInputState :: proc(state: ^InputState, events: []sdl.Event, element_ptr: rawptr) {
    element := cast(^Element)element_ptr
    for event in events {
        #partial switch event.type {
            case sdl.EventType.MOUSE_MOTION:
                mouse_x := f32(event.motion.x) / state.window_scale
                mouse_y := f32(event.motion.y) / state.window_scale
                mouse_delta_x := f32(event.motion.xrel) / state.window_scale
                mouse_delta_y := f32(event.motion.yrel) / state.window_scale
                state.mouse_position = {mouse_x, mouse_y}
                state.mouse_delta = {mouse_delta_x, mouse_delta_y}
                
            case sdl.EventType.MOUSE_BUTTON_DOWN:
                element := cast(^Element)element_ptr
                mouse_x := f32(event.motion.x) / state.window_scale
                mouse_y := f32(event.motion.y) / state.window_scale
                if isInBounds(mouse_x, mouse_y, element.bounds) {
                    state.mouse_buttons[event.button.button - 1] = true
                }

            case sdl.EventType.MOUSE_BUTTON_UP:
                if event.button.button <= 5 {
                    state.mouse_buttons[event.button.button - 1] = false
                }
        }
    }
}

isMouseButtonDown :: proc(state: ^InputState, button: u8) -> bool {
    if button >= 5 {
        return false
    }
    if button <0 {
        return false
    }
    return state.mouse_buttons[button]
}
isMouseClicked :: proc(events: []sdl.Event, element: ^Element, button_index: u8, scale: f32 = 1.5) -> bool {
    for event in events {
        if isMouseClickWithinElement(event, element, button_index, scale) {
            return true
        }
    }
    return false
}

isDragging :: proc(state: ^InputState, button: u8) -> bool {
    if isMouseButtonDown(state, button) {
        return state.mouse_delta.x != 0 || state.mouse_delta.y != 0
    }
    return false
}

getDrag :: proc(state: ^InputState, button: u8) -> [2]f32 {
    if isDragging(state, button) {
        return state.mouse_delta
    }
    return {0, 0}
}

scaleMousePosition :: proc(state: ^InputState, scale: f32) -> [2]f32 {
    return {state.mouse_position.x * scale, state.mouse_position.y * scale}
}