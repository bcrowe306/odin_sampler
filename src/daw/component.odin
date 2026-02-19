package daw 

import "core:encoding/uuid"
import "core:crypto"
import "../daw"

Component :: struct {
    using control : Control,
    addControl: proc(component: ^Component, control: rawptr, control_name: string = ""),
    controls_map: map[string]rawptr,
    removeControl: proc(component: ^Component, control: rawptr),
    controls : [dynamic]rawptr,
    activate: proc(ptr: rawptr),
    
}

    

createComponent :: proc(name: string) -> ^Component {
    context.random_generator = crypto.random_generator()
    component := new(Component)
    component.id = uuid.generate_v4()
    component.name = name
    component.enabled = true
    component.active = false
    component.initialize = initializeComponent
    component.handleInput = defaultComponentInputHandler
    component.addControl = component_addControl
    component.removeControl = component_removeControl
    component.activate = activateComponent
    component.deactivate = deactivateComponent
    return component
}


activateComponent :: proc(ptr: rawptr) {
    component := cast(^Component)ptr
    comp_control := cast(^Control)ptr
    for control_ptr in component.controls {
        control := cast(^Control)control_ptr
        control.active = true
    }
    if component.onActivate != nil {
        component.onActivate(ptr)
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
    if component.onDeInitialize != nil {
        component.onDeInitialize(ptr)
    }
}

initializeComponent :: proc(ptr: rawptr, control_surface: ^ControlSurface, device_name: string, daw: ^daw.DAW) {
    component := cast(^Component)ptr
    component.control_surface = control_surface
    component.device_name = device_name
    component.daw = daw
    for control_ptr in component.controls {
        control := cast(^Control)control_ptr
        if control.initialize != nil {
            control.initialize(control_ptr, control_surface, component.device_name, daw)
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

defaultComponentInputHandler :: proc(component_ptr: rawptr, msg: ^ShortMessage) -> bool {
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


component_addControl :: proc(component: ^Component, control:rawptr, control_name: string = "") {
    // Process additions
    exists := false
    new := cast(^Control)control
    for ptr in component.controls {
        existing_control := cast(^Control)ptr
        if new.id == existing_control.id {
            exists = true
            break
        }
    }
    if !exists {
        n := new.name
        if control_name != "" {
            n = control_name
        }
        append(&component.controls, control)

        if n != "" {
            component.controls_map[n] = control
        }
    }
}

component_removeControl :: proc(component: ^Component, control_to_remove: rawptr) {
    control_to_remove := cast(^Control)control_to_remove
    // Process removals
    for ptr, index in component.controls {
        control := cast(^Control)ptr
        if control.id == control_to_remove.id {
            ordered_remove(&component.controls, index)
            break
        }
    }
}


