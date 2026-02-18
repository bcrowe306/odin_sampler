package midi

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
    control_surfaces_callbacks: [dynamic]proc(msg: ^ShortMessage, userData: ^MidiEngine) -> bool,

    enabledDevice: proc(deviceName: string) -> bool,
    disableDevice: proc(deviceName: string) -> bool,
    midiInputCallback: proc(engine: ^MidiEngine, msg: ^ShortMessage),
    startInputThread: proc(engine: ^MidiEngine, device: ^MidiDevice),
    refreshMidiDevices: proc(engine: ^MidiEngine),
    openDeviceInput: proc(device: ^MidiDevice, engine: ^MidiEngine),
    closeDeviceInput: proc(engine: ^MidiEngine, device: ^MidiDevice),
    openDeviceOutput: proc(device: ^MidiDevice),
    closeDeviceOutput: proc(device: ^MidiDevice),
}

createMidiEngine :: proc() -> ^MidiEngine {
    engine := new(MidiEngine)
    engine.debug = false

    // Methods

    engine.midiInputCallback = midiInputCallback
    engine.startInputThread = startInputThread
    engine.refreshMidiDevices = refreshMidiDevices
    engine.openDeviceInput = openDeviceInput
    engine.closeDeviceInput = closeDeviceInput
    engine.openDeviceOutput = openDeviceOutput
    engine.closeDeviceOutput = closeDeviceOutput
    return engine
}

midiInputCallback :: proc(engine: ^MidiEngine, msg: ^ShortMessage) {
    if engine.debug {
        fmt.printfln("Device: %s, Message: %s", msg.device, msg->toHexString())
    }
    for callback in engine.control_surfaces_callbacks {
        if callback(msg, engine) {
            break
        }
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
            device.enabled = false
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
        if !device.listening {
            break
        }
        err :=portmidi.Poll(device.iStream)
        if err == portmidi.Error.GotData{
            count := portmidi.Read(device.iStream, &event[0], 1024)
            if count > 0 {
                for i in 0..<count {
                    msg := MessageFromPortMidi(event[i].message)
                    msg.device = device.name
                    if device.debug {
                        fmt.println(msg->toHexString())
                    }
                    for callback in device.subscribers {
                        engine->midiInputCallback(msg)
                    }
                }
            }
        }
        time.sleep(2 * time.Millisecond)
    }
}
