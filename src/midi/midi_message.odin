package midi

import "vendor:portmidi"
import "core:math"
import "core:fmt"


// Union type for midi messages. This will allow us to handle both regular MIDI messages and SysEx messages in
MidiMessage :: union {
    ShortMessage,
    SysexMessage,
}

ShortMessage :: struct {
    status: u8,
    data1: u8,
    data2: u8,
    isNoteOn: proc(msg : ^ShortMessage) -> bool,
    isNoteOff: proc(msg : ^ShortMessage) -> bool,
    isControlChange: proc(msg : ^ShortMessage) -> bool,
    isProgramChange: proc(msg : ^ShortMessage) -> bool,
    isPitchBend: proc(msg : ^ShortMessage) -> bool,
    isChannelPressure: proc(msg : ^ShortMessage) -> bool,
    toHexString: proc(msg : ^ShortMessage) -> string,
    getFrequency: proc(note: u8) -> f64,
    getNoteName: proc(note: u8) -> string,
    getChannel: proc(msg: ^ShortMessage) -> u8,
    getMessageType: proc(msg: ^ShortMessage) -> u8,
}

getChannel :: proc(msg: ^ShortMessage) -> u8 {
    return msg.status & 0x0F
}

getMessageType :: proc(msg: ^ShortMessage) -> u8 {
    return msg.status & 0xF0
}

isNoteOn :: proc(msg: ^ShortMessage) -> bool {
    return getMessageType(msg) == NOTE_ON && msg.data2 > 0
}

isNoteOff :: proc(msg: ^ShortMessage) -> bool {
    return (getMessageType(msg) == NOTE_OFF) || (getMessageType(msg) == NOTE_ON && msg.data2 == 0)
}

isControlChange :: proc(msg: ^ShortMessage) -> bool {
    return getMessageType(msg) == CONTROL_CHANGE
}

isProgramChange :: proc(msg: ^ShortMessage) -> bool {
    return getMessageType(msg) == PROGRAM_CHANGE
}

isPitchBend :: proc(msg: ^ShortMessage) -> bool {
    return getMessageType(msg) == PITCH_BEND
}

isChannelPressure :: proc(msg: ^ShortMessage) -> bool {
    return getMessageType(msg) == CHANNEL_PRESSURE
}

toHexString :: proc(msg: ^ShortMessage) -> string {
    return fmt.tprintf("%02X %02X %02X", msg.status, msg.data1, msg.data2)
}

getFrequency :: proc(note: u8) -> f64 {
    return 440.0 * math.pow(2.0, (cast(f64)(note) - 69.0) / 12.0)
}

getNoteName :: proc(note: u8) -> string {
    note_names := []string{"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
    octave := (note / 12) - 1
    name := note_names[note % 12]
    return fmt.tprintf("%s%d", name, octave)
}

buildMsgStruct :: proc(msg: ^ShortMessage)  {
    msg.isNoteOn = isNoteOn
    msg.isNoteOff = isNoteOff
    msg.isControlChange = isControlChange
    msg.isProgramChange = isProgramChange
    msg.isPitchBend = isPitchBend
    msg.isChannelPressure = isChannelPressure
    msg.toHexString = toHexString
    msg.getFrequency = getFrequency
    msg.getNoteName = getNoteName
    msg.getChannel = getChannel
    msg.getMessageType = getMessageType
    
} 

MessageFromBytes :: proc(bytes: []u8) -> ^ShortMessage {
    msg := new(ShortMessage)
    buildMsgStruct(msg)
    if len(bytes) < 3 {
        return msg
    }

    msg.status = bytes[0]
    msg.data1 = bytes[1]
    msg.data2 = bytes[2]
    return msg
}

MessageFromPortMidi :: proc(pm_message: portmidi.Message) -> ^ShortMessage {
    msg := new(ShortMessage)
    buildMsgStruct(msg)
    status, data1, data2 := portmidi.MessageDecompose(pm_message)
    msg.status = u8(status)
    msg.data1 = u8(data1)
    msg.data2 = u8(data2)
    return msg
}

MessageFromShort :: proc(status: u8, data1: u8, data2: u8) -> ^ShortMessage {
    msg := new(ShortMessage)
    buildMsgStruct(msg)
    msg.status = status
    msg.data1 = data1
    msg.data2 = data2
    return msg
}

// System Exclusive messages are variable-length and require special handling, so we won't include them in the MidiMessage struct. 
// Instead, we can create a separate struct for SysEx messages if needed.
// No need to include Sysex start (0xF0) and end (0xF7). They will be handled add on creation.
SysexMessage :: struct {
    data: []u8,
    toHexString: proc(msg : ^SysexMessage) -> string,
    len: proc(msg : ^SysexMessage) -> int,
    toCString: proc(msg : ^SysexMessage) -> cstring,
}


sysexLen :: proc(msg: ^SysexMessage) -> int {
    return len(msg.data)
}

toString :: proc(msg: ^SysexMessage) -> string {
    hex_string := ""
    for byte in msg.data {
        hex_string = fmt.tprintf("%s%02X ", hex_string, byte)
    }
    return hex_string
}

buildSysexStruct :: proc() -> SysexMessage {
    return SysexMessage{
        toHexString = toString,
        len = sysexLen,
        toCString = toCString,

    }
}

CreateSysexMessage :: proc(message_array: []u8) -> SysexMessage {
    sm := buildSysexStruct()
    // Add SYSEX_START at the beginning and SYSEX_END at the end of the message
    sm.data = make([]u8, len(message_array) + 2)
    sm.data[0] = SYSEX_START// Start of SysEx
    copy(sm.data[1:], message_array) // Copy the original message into the new array
    sm.data[len(sm.data) - 1] = SYSEX_END // End of SysEx
    return sm
}


toCString :: proc( msg: ^SysexMessage) -> cstring {
    bytes := make ([]u8, len(msg.data) + 1) // Create a new byte array with an extra byte for null-termination
    copy(bytes, msg.data) // Copy the original message into the new byte array
    bytes[len(msg.data)] = 0 // Null-terminate the byte array
    return cstring(&bytes[0])
}

convertToCString :: proc(msg: []u8) -> cstring {
    bytes := make ([]u8, len(msg) + 1) // Create a new byte array with an extra byte for null-termination
    copy(bytes, msg) // Copy the original message into the new byte array
    bytes[len(msg)] = 0 // Null-terminate the byte array
    return cstring(&bytes[0])
}

GenerateStatusByte :: proc(message_type: u8, channel: u8) -> u8 {
    return (message_type & 0xF0) | (channel & 0x0F)
}

GetStatusType :: proc(status_byte: u8) -> u8 {
    return status_byte & 0xF0
}

GetChannel :: proc(status_byte: u8) -> u8 {
    return status_byte & 0x0F
}