package control_surface

import "core:fmt"
import "../midi"

EventType :: enum {
    Pressed,
    Released,
    Clicked,
    DoubleClicked,
    Hold,
    LongPress,
    Increment,
    Decrement,
    IncrementFast,
    DecrementFast,
    IncrementSlow,
    DecrementSlow,
    NoteOn,
    NoteOff,
    Aftertouch,
    ControlChange,
    ProgramChange,
    ValueChange,
}

ControlEvent :: struct {
    control_name: string,
    type: EventType,
    msg: midi.ShortMessage,
    unit: f64,
}

createEvent :: proc(type: EventType, control_name: string, msg: midi.ShortMessage) -> ControlEvent {
    unit := f64(msg.data2) / 127.0
    return ControlEvent{control_name, type, msg, unit}
}