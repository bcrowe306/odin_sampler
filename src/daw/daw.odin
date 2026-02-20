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
    daw_ptr.midi_engine->initialize()
    daw_ptr.audio_engine->initialize()
    startAudioEngine(daw_ptr.audio_engine)
    audioEngineBuild(daw_ptr.audio_engine)
}

unInitialzeDaw :: proc(daw_ptr: ^DAW) {
    for control_surface_ptr in daw_ptr.midi_engine.control_surfaces {
        control_surface := cast(^ControlSurface)control_surface_ptr
        control_surface->deInitialize()
    }
    stopAudioEngine(daw_ptr.audio_engine)
    daw_ptr.audio_engine->uninitialize()
    daw_ptr.midi_engine->uninitialize() 
    free(daw_ptr.audio_engine)
    free(daw_ptr.midi_engine)
}