package daw 

import "core:thread"
import "vendor:portmidi"
import "core:fmt"
import "core:time"



MidiDevice :: struct {
    input_id: portmidi.DeviceID,
    output_id: portmidi.DeviceID,
    name: string,
    enabled: bool,
    iStream: portmidi.Stream,
    oStream: portmidi.Stream,
    sendShortMessage: proc(device: ^MidiDevice, msg: ShortMessage),
    sendSysexMessage: proc(device: ^MidiDevice, msg: ^SysexMessage),
    sendMessage: proc(device: ^MidiDevice, msg: MidiMessage),
    sendSysex: proc(device: ^MidiDevice, msg: []u8),
    sendShort: proc(device: ^MidiDevice, status: u8, data1: u8, data2: u8),
    t: ^thread.Thread,
    listening: bool,
    debug: bool,
}

buildMidiDeviceStruct :: proc() -> ^MidiDevice {
    md := new(MidiDevice)
    md.listening = false
    md.sendShortMessage = sendShortMessage
    md.sendSysexMessage = sendSysexMessage
    md.sendMessage = sendMessage
    md.sendSysex = sendSysex
    md.sendShort = sendShort
    md.debug = false
    md.enabled = true
    return md
}




sendMessage :: proc(device: ^MidiDevice, msg: MidiMessage) {
    switch &v in msg {
    case ShortMessage:
        sendShortMessage(device, v)
    case SysexMessage:
        sendSysexMessage(device, &v)
    }
}

sendShortMessage :: proc(device: ^MidiDevice, msg: ShortMessage) {
    message := portmidi.MessageCompose(i32(msg.status), i32(msg.data1), i32(msg.data2))
    err := portmidi.WriteShort(device.oStream, 0, message)
    if err != nil {
        fmt.printf("Error sending MIDI message: %s\n", err)
    }
}

sendSysexMessage :: proc(device: ^MidiDevice, msg: ^SysexMessage) {
    err := portmidi.WriteSysEx(device.oStream, 0, msg->toCString())
    if err != nil {
        fmt.printf("Error sending MIDI SysEx message: %s\n", err)
    }
}


sendSysex :: proc(device: ^MidiDevice, msg: []u8) {
    data := make([]u8, len(msg) + 2)
    data[0] = SYSEX_START// Start of SysEx
    copy(data[1:], msg) // Copy the original message into the new array
    data[len(data) - 1] = SYSEX_END // End of SysEx
    err := portmidi.WriteSysEx(device.oStream, 0, convertToCString(data))
    if err != nil {
        fmt.printf("Error sending MIDI SysEx message: %s\n", err)
    }
}

sendShort :: proc(device: ^MidiDevice, status: u8, data1: u8, data2: u8) {
    msg := MessageFromShort(status, data1, data2)
    fmt.printf("Sending Short message: Status: %02X, Data1: %02X, Data2: %02X\n", status, data1, data2)
    sendShortMessage(device, msg^)
}

