package daw 

import "core:encoding/uuid"
import "core:crypto"
import daw_pkg "../daw"
import "../app"

Control :: struct {
    id: uuid.Identifier,
    name: string,
    channel: u8,
    status: u8,
    identifier: u8,
    enabled: bool,
    active: bool,
    daw: ^daw_pkg.DAW,
    device_name: string,
    control_surface: ^ControlSurface,
    initialized: bool,
    initialize: proc(ptr: rawptr, control_surface: ^ControlSurface, device_name: string, daw: ^daw_pkg.DAW),
    deInitialize: proc(ptr: rawptr),
    handleInput : proc(ptr: rawptr, msg: ^ShortMessage) -> bool,

    deactivate: proc(ptr: rawptr),

    sendMidi: proc(ptr: rawptr, msg: ShortMessage),
    sendSysex: proc(ptr: rawptr, msg: []u8),

    // User overrides
    onInitialize: proc(ptr: rawptr),
    onDeInitialize: proc(ptr: rawptr),
    onActivate: proc(ptr: rawptr),
    onDeactivate: proc(ptr: rawptr),
    onInput: proc(ptr: rawptr, msg: ^ShortMessage) -> bool,
}

initializeControl :: proc(ptr: rawptr, control_surface: ^ControlSurface, device_name: string, daw: ^daw_pkg.DAW) {
    control := cast(^Control)ptr
    control.control_surface = control_surface
    control.device_name = device_name
    control.daw = daw
    control.initialized = true
    if control.onInitialize != nil {
        control.onInitialize(ptr)
    }
}

deInitializeControl :: proc(ptr: rawptr) {
    control := cast(^Control)ptr
    control.initialized = false
    if control.onDeInitialize != nil {
        control.onDeInitialize(ptr)
    }
}


deactivateControl :: proc(ptr: rawptr) {
    control := cast(^Control)ptr
    control.active = false
    if control.onDeactivate != nil {
        control.onDeactivate(ptr)
    }
}


defaultInputHandler :: proc(ptr: rawptr, msg: ^ShortMessage) -> bool {
    // By default, we emit an event for any message that matches the control's assigned MIDI message
    control := cast(^Control)ptr
    if control.onInput != nil {
        return control.onInput(ptr, msg)
    }
    return false
}

configureControl :: proc(new_control: rawptr, name: string) {
    context.random_generator = crypto.random_generator()
    control := cast(^Control)new_control
    control.id = uuid.generate_v4()
    control.name = name
    control.enabled = true
    control.active = false
    control.handleInput = defaultInputHandler
    control.initialize = initializeControl
    control.deInitialize = deInitializeControl
    control.deactivate = deactivateControl
    control.sendMidi = control_sendMidi
    control.sendSysex = control_sendSysex
}

control_sendMidi :: proc(control_ptr: rawptr, msg: ShortMessage) {
    control := cast(^Control)control_ptr
    if control.daw != nil && control.daw.midi_engine != nil {
        control.daw.midi_engine.sendMsg(control.daw.midi_engine, control.device_name, msg)
    }
}

control_sendSysex :: proc(control_ptr: rawptr, msg: []u8) {
    control := cast(^Control)control_ptr
    if control.daw != nil && control.daw.midi_engine != nil {
        control.daw.midi_engine.sendSysexMsg(control.daw.midi_engine, control.device_name, msg)
    }
}