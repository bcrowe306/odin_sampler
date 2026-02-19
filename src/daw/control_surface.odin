package daw 

import "core:fmt"
import "core:thread"
import "core:encoding/uuid"
import "../daw"
import "core:crypto"

// Control Surface represents a connected MIDI control surface device, such as a MIDI keyboard, pad controller, or mixer.
// It is used to interface with the DAW using components and controls that allow you to manipulate the DAW in real-time using physical hardware.
ControlSurface :: struct {
    // Usage:
    // Create a new control surface or override the default one for custom behavior. Override on[methods] lifecycle methods for custom behavior.
    //      myControlSurface := createGenericControlSurface("My Control Surface")
    // Add components to the control surface. Components represent individual controls on the hardware, such as buttons, knobs, sliders, or pads.
    //      myControlSurface.components = append(myControlSurface.components, cast(rawptr)myButtonControl)
    // Add the control surface to the DAW. This will initialize the control surface and its components, allowing them to start receiving MIDI input and interacting with the DAW.
    //      daw->addControlSurface(myControlSurface)
    id: uuid.Identifier,
    name: string,
    device: ^MidiDevice,
    device_name: string,
    daw: ^daw.DAW,
    active: bool,
    components: [dynamic]rawptr,
    handleInput: proc(control_surface_ptr: rawptr, msg: ^ShortMessage) -> bool,
    initialize: proc(control_surface_ptr: rawptr, daw: ^daw.DAW, device_name: string),
    deInitialize: proc(control_surface_ptr: rawptr),
    activate: proc(control_surface_ptr: rawptr),
    deactivate: proc(control_surface_ptr: rawptr),
    sendMidi: proc(control_surface_ptr: rawptr, msg: ShortMessage),
    sendSysex: proc(control_surface_ptr: rawptr, msg: []u8),
    thread: thread.Thread,
    
    // User override
    onInitialize: proc(control_surface_ptr: rawptr, daw: ^daw.DAW, device_name: string),

    // User override
    onDeInitialize: proc(control_surface_ptr: rawptr),

    // User override
    onActivate: proc(control_surface_ptr: rawptr),

    // User override
    onDeactivate: proc(control_surface_ptr: rawptr),

    // User override
    run: proc(control_surface_ptr: rawptr),
}

createGenericControlSurface :: proc(name: string) -> ^ControlSurface {
    control_surface := new(ControlSurface)
    configureControlSurfaceDefaults(control_surface, name)
    return control_surface
}

configureControlSurfaceDefaults :: proc(control_surface_type: ^$T, name: string) {
    context.random_generator = crypto.random_generator()
    control_surface := cast(^ControlSurface)control_surface_type
    control_surface.id = uuid.generate_v4()
    control_surface.name = name
    control_surface.device_name = ""
    control_surface.handleInput = controlSurfaceHandleInput
    control_surface.initialize = initializeControlSurface
    control_surface.deInitialize = deInitializeControlSurface
    control_surface.run = nil
    control_surface.activate = control_surface_activate
    control_surface.deactivate = control_surface_deactivate
    control_surface.sendMidi = control_surface_sendMidi
    control_surface.sendSysex = control_surface_sendSysex

}

control_surface_activate :: proc(control_surface_ptr: rawptr) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    control_surface.active = true
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        component.active = true
        if component.activate != nil {
            component.activate(component)
        }
        activateComponent(component)
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


controlSurfaceHandleInput :: proc(control_surface_ptr: rawptr, msg: ^ShortMessage) -> bool {
    control_surface := cast(^ControlSurface)control_surface_ptr
    handled := false
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        if component.handleInput != nil && component.enabled && component.active {
            if component.handleInput(component, msg) {
                handled = true
                break
            }
        }
    }
    return handled
}

initializeControlSurface :: proc(control_surface_ptr: rawptr, daw: ^daw.DAW, device_name: string) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    control_surface.daw = daw
    control_surface.device_name = device_name
    for component_ptr in control_surface.components {
        component := cast(^Component)component_ptr
        if component.initialize != nil {
            component.initialize(component, control_surface, control_surface.device_name, control_surface.daw)
        }
    }
    if control_surface.onInitialize != nil {
        control_surface.onInitialize(cast(rawptr)control_surface, daw, device_name)
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

control_surface_sendMidi :: proc(control_surface_ptr: rawptr, msg: ShortMessage) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    if control_surface.daw != nil && control_surface.daw.midi_engine != nil {
        control_surface.daw.midi_engine.sendMsg(control_surface.daw.midi_engine, control_surface.device_name, msg)
    }
}

control_surface_sendSysex :: proc(control_surface_ptr: rawptr, msg: []u8) {
    control_surface := cast(^ControlSurface)control_surface_ptr
    if control_surface.daw != nil && control_surface.daw.midi_engine != nil {
        control_surface.daw.midi_engine.sendSysexMsg(control_surface.daw.midi_engine, control_surface.device_name, msg)
    }
}