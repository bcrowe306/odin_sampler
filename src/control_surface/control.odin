package control_surface

import "core:encoding/uuid"
import "core:crypto"
import "../midi"
import "../daw"

Control :: struct {
    id: uuid.Identifier,
    name: string,
    enabled: bool,
    active: bool,
    device: ^midi.MidiDevice,
    daw: ^daw.DAW,
    control_surface: ^ControlSurface,
    initialized: bool,
    initialize: proc(ptr: rawptr, control_surface: ^ControlSurface, device: ^midi.MidiDevice, daw: ^daw.DAW),
    deInitialize: proc(ptr: rawptr),
    handleInput : proc(ptr: rawptr, msg: ^midi.ShortMessage) -> bool,
    activate: proc(ptr: rawptr),
    deactivate: proc(ptr: rawptr),
    listeners: [dynamic]proc(event: ControlEvent),
    subscribe: proc(ptr: rawptr, listener: proc(event: ControlEvent)),
    unsubscribe: proc(ptr: rawptr, listener: proc(event: ControlEvent)),
    emit: proc(ptr: rawptr, event: ControlEvent),

    // User overrides
    onInitialize: proc(ptr: rawptr),
    onDeInitialize: proc(ptr: rawptr),
    onActivate: proc(ptr: rawptr),
    onDeactivate: proc(ptr: rawptr),
    onInput: proc(ptr: rawptr, msg: ^midi.ShortMessage) -> bool,
}

initializeControl :: proc(ptr: rawptr, control_surface: ^ControlSurface, device: ^midi.MidiDevice, daw: ^daw.DAW) {
    control := cast(^Control)ptr
    control.control_surface = control_surface
    control.device = device
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

activateControl :: proc(ptr: rawptr) {
    control := cast(^Control)ptr
    control.active = true
    if control.onActivate != nil {
        control.onActivate(ptr)
    }
}

deactivateControl :: proc(ptr: rawptr) {
    control := cast(^Control)ptr
    control.active = false
    if control.onDeactivate != nil {
        control.onDeactivate(ptr)
    }
}

controlSubscribe :: proc(ptr: rawptr, listener: proc(event: ControlEvent)) {
    control := cast(^Control)ptr
    append(&control.listeners, listener)
}

controlUnsubscribe :: proc(ptr: rawptr, listener: proc(event: ControlEvent)) {
    control := cast(^Control)ptr
    for existing_listener, i in control.listeners {
        if existing_listener == listener {
            ordered_remove(&control.listeners, i)
            break
        }
    }
}

emitControlEvent :: proc(ptr: rawptr, event: ControlEvent) {
    control := cast(^Control)ptr
    for listener in control.listeners {
        if listener != nil {
            listener(event)
        }
    }
}

defaultInputHandler :: proc(ptr: rawptr, msg: ^midi.ShortMessage) -> bool {
    // By default, we emit an event for any message that matches the control's assigned MIDI message
    control := cast(^Control)ptr
    if control.onInput != nil {
        return control.onInput(ptr, msg)
    }
    return false
}

configureControl :: proc(new_control: $T, name: string) {
    context.random_generator = crypto.random_generator()
    control := cast(^Control)new_control
    control.id = uuid.generate_v4()
    control.name = name
    control.enabled = true
    control.active = false
    control.handleInput = defaultInputHandler
    control.subscribe = controlSubscribe
    control.unsubscribe = controlUnsubscribe
    control.emit = emitControlEvent
    control.initialize = initializeControl
    control.deInitialize = deInitializeControl
    control.activate = activateControl
    control.deactivate = deactivateControl
    control.onInitialize = nil
    control.onDeInitialize = nil
    control.onActivate = nil
    control.onDeactivate = nil
    control.onInput = nil
}