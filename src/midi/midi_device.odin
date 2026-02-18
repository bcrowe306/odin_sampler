package midi

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
    startInput: proc(device: ^MidiDevice),
    stopInput: proc(device: ^MidiDevice),
    listening: bool,
    subscribers: [dynamic]proc(msg: ^ShortMessage),
    subscribe: proc(device: ^MidiDevice, callback: proc(msg: ^ShortMessage)),
    unsubscribe: proc(device: ^MidiDevice, callback: proc(msg: ^ShortMessage)),
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
    md.startInput = midiDeviceStartInput
    md.stopInput = midiDeviceStopInput
    md.subscribe = midiDeviceSubscribe
    md.unsubscribe = midiDeviceUnsubscribe
    md.debug = false
    md.enabled = true
    return md
}

midiDeviceSubscribe :: proc(device: ^MidiDevice, callback: proc(msg: ^ShortMessage)) {
    append(&device.subscribers, callback)
}

midiDeviceUnsubscribe :: proc(device: ^MidiDevice, callback: proc(msg: ^ShortMessage)) {
    for i in 0..<len(device.subscribers) {
        if device.subscribers[i] == callback {
            ordered_remove(&device.subscribers, i)
            break
        }
    }
}


midiDeviceStartInput :: proc(device: ^MidiDevice) {
    device.t = thread.create(midiDeviceListen)
    device.t.data = cast(rawptr)device
    device.listening = true
    thread.start(device.t)
}

midiDeviceStopInput :: proc(device: ^MidiDevice) {
    device.listening = false
    if device.t != nil {
        thread.join(device.t)
        device.t = nil
    }
}

midiDeviceListen :: proc(t: ^thread.Thread) {
    device := cast(^MidiDevice)t.data
    event: []portmidi.Event = make([]portmidi.Event, 1024)
    for {
        if !device.listening {
            break
        }
        err :=portmidi.Poll(device.iStream)
        if err == portmidi.Error.GotData{
            count := portmidi.Read(device.iStream, &event[0], 1024)
            if count > 0 {
                for i in 0..<count {
                    msg := MessageFromPortMidi(event[i].message)
                    if device.debug {
                        fmt.println(msg->toHexString())
                    }
                    for callback in device.subscribers {
                        callback(msg)
                    }
                }
            }
        }
        time.sleep(5 * time.Millisecond)
    }
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


GetDeviceByName :: proc(name: string) -> ^MidiDevice {
    midi_devices := portmidi.CountDevices()
    md := buildMidiDeviceStruct()
    input_found := false
    output_found := false
    for i in 0..<midi_devices {
        device_info := portmidi.GetDeviceInfo(cast(portmidi.DeviceID)i)
        if device_info.name == fmt.ctprint(name) {
            fmt.printf("MIDI device: %s, Id: %d\n", device_info.name, i)
            
            
            md.name = string(device_info.name)

            if device_info.input {
                
                md.input_id = cast(portmidi.DeviceID)i
                input_err := portmidi.OpenInput(&md.iStream, md.input_id, nil, portmidi.DEFAULT_SYSEX_BUFFER_SIZE, nil, nil)
                if input_err != nil {
                    fmt.printf("Error opening MIDI input stream: %s\n", input_err)
                } else {
                    input_found = true
                }
            }
            
            if device_info.output {
                output_found = true
                md.output_id = cast(portmidi.DeviceID)i
                output_err := portmidi.OpenOutput(&md.oStream, md.output_id, nil, portmidi.DEFAULT_SYSEX_BUFFER_SIZE, nil, nil, 0)
                if output_err != nil {
                    fmt.printf("Error opening MIDI output stream: %s\n", output_err)
                } else {
                    output_found = true
                }
            }
            
        }
    }
    if input_found && output_found {
        return md
    }
    else {
        fmt.printf("MIDI device '%s' does not have both input and output capabilities.\n", name)
        // delete md // Clean up the allocated MidiDevice struct if it was created
        free(md)
        return nil
    }
}