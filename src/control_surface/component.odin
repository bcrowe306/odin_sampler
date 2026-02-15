package control_surface

import "core:encoding/uuid"
import "../midi"
import "core:crypto"
import "../daw"

Component :: struct {
    using control : Control,
    addControl: proc(component: ^Component, control: rawptr),
    removeControl: proc(component: ^Component, control: rawptr),
    controls : [dynamic]rawptr,
}

    

createComponent :: proc(name: string) -> ^Component {
    context.random_generator = crypto.random_generator()
    component := new(Component)
    component.id = uuid.generate_v4()
    component.name = name
    component.enabled = true
    component.active = false
    component.handleInput = defaultComponentInputHandler
    component.addControl = addControl
    component.removeControl = removeControl
    component.activate = activateComponent
    component.deactivate = deactivateComponent
    return component
}


activateComponent :: proc(ptr: rawptr) {
    component := cast(^Component)ptr
    for control_ptr in component.controls {
        control := cast(^Control)control_ptr
        control.active = true
        if control.activate != nil {
            control.activate(control_ptr)
        }
    }
}

deactivateComponent :: proc(ptr: rawptr) {
    component := cast(^Component)ptr
    for control_ptr in component.controls {
        control := cast(^Control)control_ptr
        control.active = false
        if control.deactivate != nil {
            control.deactivate(control_ptr)
        }
    }
}

initializeComponent :: proc(ptr: rawptr, control_surface: ^ControlSurface, device: ^midi.MidiDevice, daw: ^daw.DAW) {
    component := cast(^Component)ptr
    component.control_surface = control_surface
    component.device = device
    component.daw = daw
    for control_ptr in component.controls {
        control := cast(^Control)control_ptr
        if control.initialize != nil {
            control.initialize(control_ptr, control_surface, device, daw)
        }
    }
    if component.onInitialize != nil {
        component.onInitialize(ptr)
    }
}

deInitializeComponent :: proc(ptr: rawptr) {
    component := cast(^Component)ptr
    for control_ptr in component.controls {
        control := cast(^Control)control_ptr
        if control.deInitialize != nil {
            control.deInitialize(control_ptr)
        }
    }
    if component.onDeInitialize != nil {
        component.onDeInitialize(ptr)
    }
}

defaultComponentInputHandler :: proc(component_ptr: rawptr, msg: ^midi.ShortMessage) -> bool {
    handled := false
    component := cast(^Component)component_ptr
    for control_ptr in component.controls {
        control := cast(^Control)control_ptr
        if control.enabled && control.active && control.handleInput != nil {
            if control.handleInput(control_ptr, msg) {
                handled = true
            }
        }   
    }
    return handled
}


addControl :: proc(component: ^Component, new_control_type: $T) {
    new_ptr := cast(rawptr)new_control_type
    // Process additions
    exists := false
    new := cast(^Control)new_ptr
    for ptr in component.controls {
        control := cast(^Control)ptr
        if new.id == control.id {
            exists = true
            break
        }
    }
    if !exists {
        append(&component.controls, new_ptr)
    }
}

removeControl :: proc(component: ^Component, control_to_remove_type: $T) {
    control_to_remove := cast(^Control)control_to_remove_type
    // Process removals
    for ptr, index in component.controls {
        control := cast(^Control)ptr
        if control.id == control_to_remove.id {
            ordered_remove(&component.controls, index)
            break
        }
    }
}


