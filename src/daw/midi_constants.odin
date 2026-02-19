package daw 

MIDI_STATUS :: enum(u8) {
    NOTE_OFF = 0x80,
    NOTE_ON = 0x90,
    POLY_PRESSURE = 0xA0,
    CONTROL_CHANGE = 0xB0,
    PROGRAM_CHANGE = 0xC0,
    CHANNEL_PRESSURE = 0xD0,
    PITCH_BEND = 0xE0,
    
    SYSEX_START = 0xF0,
    MIDI_TIME_CODE = 0xF1,
    SONG_POSITION_POINTER = 0xF2,
    SONG_SELECT = 0xF3,
    TUNE_REQUEST = 0xF6,
    SYSEX_END = 0xF7,
}
// Status Messages
NOTE_OFF: u8 = 0x80
NOTE_ON: u8 = 0x90
POLY_PRESSURE: u8 = 0xA0
CONTROL_CHANGE: u8 = 0xB0
PROGRAM_CHANGE: u8 = 0xC0
CHANNEL_PRESSURE: u8 = 0xD0
PITCH_BEND: u8 = 0xE0

// System Common Messages
SYSEX_START: u8 = 0xF0
MIDI_TIME_CODE: u8 = 0xF1
SONG_POSITION_POINTER: u8 = 0xF2
SONG_SELECT: u8 = 0xF3
TUNE_REQUEST: u8 = 0xF6
SYSEX_END: u8 = 0xF7


toMsbLsb :: proc(value: u16) -> (u8, u8) {
    msb := u8((value >> 7) & 0x7F)
    lsb := u8(value & 0x7F)
    return msb, lsb
}

toMsbLsbArr :: proc(value: u16) -> [2]u8 {
    msb, lsb := toMsbLsb(value)
    return [2]u8{msb, lsb}
}


fromMsbLsb :: proc(msb: u8, lsb: u8) -> u16 {
    return (u16(msb) << 7) | u16(lsb)
}
