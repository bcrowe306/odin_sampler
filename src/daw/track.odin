package daw

import "core:encoding/uuid"
import ma "vendor:miniaudio"
import "core:crypto"

TrackType :: enum {
    Audio,
    Midi,
    Instrument,
}

Track :: struct {
    id: uuid.Identifier,
    type: TrackType,
    name: string,
    volume: ^FloatParameter,
    pan: ^FloatParameter,
    mute: ^BoolParameter,
    solo: ^BoolParameter,
    parameters: []^Parameter,
    
}

createTrack :: proc(name: string, type: TrackType = TrackType.Instrument) -> ^Track {
    context.random_generator = crypto.random_generator()
    new_track := new(Track)
    new_track.id = uuid.generate_v4()
    new_track.name = name
    new_track.type = type
    new_track.volume = createDecibelParam("Volume")
    new_track.pan = createFParam("Pan", 0.0, -1.0, 1.0, 0.01, 0.001)
    new_track.mute = createBoolParam("Mute", false)
    new_track.solo = createBoolParam("Solo", false)
    new_track.parameters = []^Parameter{
        new_track.volume, 
        new_track.pan, 
        new_track.mute, 
        new_track.solo,
    }
    return new_track
}