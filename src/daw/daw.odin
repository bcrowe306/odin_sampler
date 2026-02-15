package daw

import "core:encoding/uuid"
import "core:fmt"

Track :: struct {
    id: uuid.Identifier,
    name: string,
    volume: f64,
    pan: f64,
    mute: bool,
    solo: bool,
    arm: bool,
}


DAW :: struct {
    tracks: [dynamic]Track,
}