package audio

import "core:encoding/uuid"
import ma "vendor:miniaudio"

Track :: struct {
    id: uuid.Identifier,
    name: string,
    volume: f32,
    pan: f32,
    mute: bool,
    solo: bool,
    playhead: ^Playhead,
}