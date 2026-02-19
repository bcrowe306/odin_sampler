package daw 

import "core:thread"
import "vendor:portmidi"
import "core:fmt"
import "core:time"

// TODO: FInish implementing MIDI output functionality and control surface feedback
// TODO: Finish device enable/disable functionality and use it in the UI
// TODO: Implement auto-enable on initialize engine
// TODO: Pipe Midi msg to control_surface, and then to daw, and then to audio engine. This will allow for more flexible routing and processing of MIDI messages.

InputThreadData :: struct {
    device: ^MidiDevice,
    engine: ^MidiEngine,
    running: bool,
}

MidiEngine :: struct {
    devices: map[string]^MidiDevice,
    debug: bool,
    input_threads: map[string]^thread.Thread,
    control_surfaces: [dynamic]rawptr,
    auto_start_all: bool,

    midiInputCallback: proc(engine: ^MidiEngine, msg: ^ShortMessage),
    startInputThread: proc(engine: ^MidiEngine, device: ^MidiDevice),
    refreshMidiDevices: proc(engine: ^MidiEngine),
    openDeviceInput: proc(device: ^MidiDevice, engine: ^MidiEngine),
    closeDeviceInput: proc(engine: ^MidiEngine, device: ^MidiDevice),
    openDeviceOutput: proc(device: ^MidiDevice),
    closeDeviceOutput: proc(device: ^MidiDevice),
    initialize: proc(engine: ^MidiEngine),
    uninitialize: proc(engine: ^MidiEngine),
    enableDevice: proc(engine: ^MidiEngine, deviceName: string) -> bool,
    disableDevice: proc(engine: ^MidiEngine, deviceName: string) -> bool,
    sendMsg: proc(engine: ^MidiEngine, deviceName: string, msg: ShortMessage),
    sendSysexMsg: proc(engine: ^MidiEngine, deviceName: string, msg: []u8),
}

createMidiEngine :: proc() -> ^MidiEngine {
    engine := new(MidiEngine)
    engine.debug = false
    engine.auto_start_all = true

    // Methods

    engine.midiInputCallback = midiInputCallback
    engine.startInputThread = startInputThread
    engine.refreshMidiDevices = refreshMidiDevices
    engine.openDeviceInput = openDeviceInput
    engine.closeDeviceInput = closeDeviceInput
    engine.openDeviceOutput = openDeviceOutput
    engine.closeDeviceOutput = closeDeviceOutput
    engine.initialize = initializeMidiEngine
    engine.enableDevice = enabledDevice
    engine.disableDevice = disableDevice
    engine.sendMsg = sendMsg
    engine.sendSysexMsg = sendSysexMsg
    engine.uninitialize = unInitializeMidieEngine
    return engine
}

initializeMidiEngine :: proc(engine: ^MidiEngine) {
    portmidi.Initialize()
    engine.refreshMidiDevices(engine)
    if engine.auto_start_all {
        startAllDevices(engine)
    }
}

unInitializeMidieEngine :: proc(engine: ^MidiEngine) {
    stopAllDevices(engine)
    portmidi.Terminate()
}

midiInputCallback :: proc(engine: ^MidiEngine, msg: ^ShortMessage) {
    if engine.debug {
        fmt.printfln("Device: %s, Message: %s", msg.device, msg->toHexString())
    }
    for control_surface_ptr in engine.control_surfaces {
        control_surface := cast(^ControlSurface)control_surface_ptr
        if control_surface.handleInput != nil && control_surface.active {
            if control_surface.handleInput(control_surface, msg) {
                break
            }
        }
    }
}

startAllDevices :: proc(engine: ^MidiEngine) {
    for _, device in engine.devices {
        if device.enabled {
            engine.openDeviceInput(device, engine)
            engine.openDeviceOutput(device)
        }
    }
}

stopAllDevices :: proc(engine: ^MidiEngine) {
    for _, device in engine.devices {
        engine.closeDeviceInput(engine, device)
        engine.closeDeviceOutput(device)
    }
}

refreshMidiDevices :: proc(engine: ^MidiEngine) {
    deviceCount := portmidi.CountDevices()
    for i in 0..<deviceCount {
        info := portmidi.GetDeviceInfo(cast(portmidi.DeviceID)i)
        device_name := fmt.tprint(info.name)
        device, exists := engine.devices[device_name]
        if !exists {
            device = buildMidiDeviceStruct()
            engine.devices[device_name] = device
            device.enabled = true
        }
        device.name = device_name
        if cast(bool)info.input {
            device.input_id = cast(portmidi.DeviceID)i
        }
        if cast(bool)info.output {
            device.output_id = cast(portmidi.DeviceID)i
        }
    }
}

openDeviceOutput :: proc(device: ^MidiDevice) {
    if device.output_id != -1 {
        output_err := portmidi.OpenOutput(&device.oStream, device.output_id, nil, portmidi.DEFAULT_SYSEX_BUFFER_SIZE, nil, nil, 0)
        if output_err != nil {
            fmt.printf("Error opening MIDI output stream: %s\n", output_err)
        } 
    }
}

closeDeviceOutput :: proc(device: ^MidiDevice) {
    if device.oStream != nil {
        portmidi.Close(device.oStream)
        device.oStream = nil
    }
}


openDeviceInput :: proc(device: ^MidiDevice, engine: ^MidiEngine) {
    if device.input_id != -1 {
        input_err := portmidi.OpenInput(&device.iStream, device.input_id, nil, portmidi.DEFAULT_SYSEX_BUFFER_SIZE, nil, nil)
        if input_err != nil {
            fmt.printf("Error opening MIDI input stream: %s\n", input_err)
        } 
    }
    if input_thread, exists := engine.input_threads[device.name]; exists {
        thread_data := cast(^InputThreadData)input_thread.data
        thread_data.running = false
        thread.join(input_thread)
    }
    engine->startInputThread(device)
}


closeDeviceInput :: proc(engine: ^MidiEngine, device: ^MidiDevice) {
    // Stop the input thread if it's running
    if input_thread, exists := engine.input_threads[device.name]; exists {
        thread_data := cast(^InputThreadData)input_thread.data
        thread_data.running = false
        thread.join(input_thread)
    }

    // Close the MIDI input stream
    if device.iStream != nil {
        portmidi.Close(device.iStream)
        device.iStream = nil
    }
}

startInputThread :: proc(engine: ^MidiEngine, device: ^MidiDevice) {
    data := new(InputThreadData)
    data.device = device
    data.engine = engine
    data.running = true
    engine.input_threads[device.name] = thread.create(engineListenDevice)
    engine.input_threads[device.name].data = cast(rawptr)data
    thread.start(engine.input_threads[device.name])
}

engineListenDevice :: proc(thread: ^thread.Thread) {
    data := cast(^InputThreadData)thread.data
    device := data.device
    engine := data.engine
    event: []portmidi.Event = make([]portmidi.Event, 1024)
    for data.running {
        err :=portmidi.Poll(device.iStream)
        if err == portmidi.Error.GotData{
            count := portmidi.Read(device.iStream, &event[0], 1024)
            if count > 0 {
                for i in 0..<count {
                    msg := MessageFromPortMidi(event[i].message)
                    msg.device = device.name
                    if !device.enabled {
                        continue
                    }
                    if device.debug {
                        fmt.println(msg->toHexString())
                    }
                    engine->midiInputCallback(msg)
                }
            }
        }
        time.sleep(2 * time.Millisecond)
    }
}

enabledDevice :: proc(engine: ^MidiEngine, deviceName: string) -> bool {
    device, exists := engine.devices[deviceName]
    if exists {
        device.enabled = true
        return true
    }
    return false
}

disableDevice :: proc(engine: ^MidiEngine, deviceName: string) -> bool {
    device, exists := engine.devices[deviceName]
    if exists {
        device.enabled = false
        return true
    }
    return false
}

sendMsg :: proc (engine: ^MidiEngine, deviceName: string, msg: ShortMessage) {
    device, exists := engine.devices[deviceName]
    if exists && device.oStream != nil && device.enabled {
        message := portmidi.MessageCompose(i32(msg.status), i32(msg.data1), i32(msg.data2))
        portmidi.WriteShort(device.oStream,0, message)
    }
}

sendSysexMsg :: proc(engine: ^MidiEngine, deviceName: string, msg: []u8) {
    if device, exists := engine.devices[deviceName]; exists && device.oStream != nil && device.enabled {
        data := make([]u8, len(msg) + 2)
        data[0] = SYSEX_START// Start of SysEx
        copy(data[1:], msg) // Copy the original message into the new array
        data[len(data) - 1] = SYSEX_END // End of SysEx
        err := portmidi.WriteSysEx(device.oStream, 0, convertToCString(data))
        if err != nil {
            fmt.printf("Error sending MIDI SysEx message: %s\n", err)
        }
    }
}
