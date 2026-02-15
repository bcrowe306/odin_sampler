package control_surface

import "core:thread"
import "core:encoding/uuid"
import "../midi"
import "../daw"
import "core:crypto"

ControlSurface :: struct {
    id: uuid.Identifier,
    name: string,
    device: ^midi.MidiDevice,
    daw: ^daw.DAW,
    active: bool,
    enabled: bool,
    components: [dynamic]rawptr,
    handleInput: proc(control_surface_ptr: rawptr, msg: ^midi.ShortMessage),
    initialize: proc(control_surface_ptr: rawptr),
    deInitialize: proc(control_surface_ptr: rawptr),
    activate: proc(control_surface_ptr: rawptr),
    deactivate: proc(control_surface_ptr: rawptr),
    thread: thread.Thread,
    
    // User override
    onInitialize: proc(control_surface_ptr: rawptr),

    // User override
    onDeInitialize: proc(control_surface_ptr: rawptr),

    // User override
    onActivate: proc(control_surface_ptr: rawptr),

    // User override
    onDeactivate: proc(control_surface_ptr: rawptr),

    // User override
    run: proc(control_surface_ptr: rawptr),
}

createGenericControlSurface :: proc(name: string, device: ^midi.MidiDevice, daw: ^daw.DAW) -> ^ControlSurface {
    control_surface := new(ControlSurface)
    configureControlSurfaceDefaults(control_surface, name, device, daw)
    return control_surface
}

configureControlSurfaceDefaults :: proc(control_surface_type: ^$T, name: string, device: ^midi.MidiDevice, daw: ^daw.DAW) {
    context.random_generator = crypto.random_generator()
    control_surface := cast(^ControlSurface)control_surface_type
    control_surface.id = uuid.generate_v4()
    control_surface.name = name
    control_surface.device = device
    control_surface.daw = daw
    control_surface.handleInput = controlSurfaceHandleInput
    control_surface.initialize = initializeControlSurface
    control_surface.deInitialize = deInitializeControlSurface
    control_surface.run = nil
    control_surface.activate = control_surface_activate
    control_surface.deactivate = control_surface_deactivate
}

control_surface_activate :: proc(control_surface_ptr: rawptr) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        component.active = true
        if component.activate != nil {
            component.activate(component)
        }
    }
}

control_surface_deactivate :: proc(control_surface_ptr: rawptr) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        component.active = false
        if component.deactivate != nil {
            component.deactivate(component)
        }
    }
}


controlSurfaceHandleInput :: proc(control_surface_ptr: rawptr, msg: ^midi.ShortMessage)  {
    control_surface := cast(^ControlSurface)control_surface_ptr
    // layer_len := len(control_surface.layers)
    // for index := layer_len - 1; index >= 0; index -= 1 {
    //     layer := cast(^Layer)control_surface.layers[index]
    //     if layer.handleInput(layer, msg) {
    //         break
    //     }
    // }
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        if component.handleInput != nil && component.enabled && component.active {
            if component.handleInput(component, msg) {
                break
            }
        }
    }
}

initializeControlSurface :: proc(control_surface_ptr: rawptr) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        if component.initialize != nil {
            component.initialize(component, control_surface, control_surface.device, control_surface.daw)
        }
    }
    if control_surface.onInitialize != nil {
        control_surface.onInitialize(cast(rawptr)control_surface)
    }
}

deInitializeControlSurface :: proc(control_surface_ptr: rawptr) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        if component.deInitialize != nil {
            component.deInitialize(component)
        }
    }
    if control_surface.onDeInitialize != nil {
        control_surface.onDeInitialize(cast(rawptr)control_surface)
    }
}