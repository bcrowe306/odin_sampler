package daw

import "core:fmt"

DAW :: struct {
    tracks: Tracks,
    handleMidiInput: proc(daw_ptr: ^DAW, msg: ^ShortMessage) ,
    midi_engine: ^MidiEngine,
    audio_engine: ^AudioEngine,
    playhead: ^Playhead,
    metronome: MetronomeNode,
    transport: Transport,

    // Methods
    initialize: proc(daw_ptr: ^DAW),
    unInitialzeDaw: proc(daw_ptr: ^DAW),
    addControlSurface: proc(daw_ptr: ^DAW, control_surface_ptr: rawptr, device_name: string = ""),
}

createDAW :: proc() -> ^DAW {
    daw := new(DAW)
    daw.tracks = createTracks()
    daw.midi_engine = createMidiEngine()
    daw.audio_engine = createAudioEngine()
    daw.metronome = createMetronomeNode()
    daw.transport = createTransport(daw)
    daw.handleMidiInput = handleMidiInputDaw
    daw.initialize = initializeDaw
    daw.unInitialzeDaw = unInitialzeDaw
    daw.addControlSurface = addControlSurface
    return daw
}

handleMidiInputDaw :: proc(daw_ptr: ^DAW, msg: ^ShortMessage) {
    daw := daw_ptr
}

addControlSurface :: proc(daw_ptr: ^DAW, control_surface_ptr: rawptr, device_name: string = "") {
    control_surface := cast(^ControlSurface)control_surface_ptr
    if device_name == "" && control_surface.device_name == "" {
        fmt.printf("No device name provided for control surface. Cannot add to DAW.\n")
        return
    }
    dn := device_name
    if dn == "" {
        dn = control_surface.device_name
    }
    append(&daw_ptr.midi_engine.control_surfaces, control_surface_ptr)
    control_surface->initialize(daw_ptr, dn)
    control_surface->activate()
}

initializeDaw :: proc(daw_ptr: ^DAW) {
    daw := daw_ptr
    daw.midi_engine->initialize()
    daw.audio_engine->initialize()
    daw.audio_engine->start()
}

unInitialzeDaw :: proc(daw_ptr: ^DAW) {
    daw := daw_ptr
    for control_surface_ptr in daw.midi_engine.control_surfaces {
        control_surface := cast(^ControlSurface)control_surface_ptr
        control_surface->deInitialize()
    }
    daw.audio_engine->stop()
    daw.audio_engine->uninitialize()
    daw.midi_engine->uninitialize() 
    free(daw.audio_engine)
    free(daw.midi_engine)
}