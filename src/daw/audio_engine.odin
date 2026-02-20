package daw

import "core:mem"
import "core:crypto"
import "core:math"
import "base:runtime"
import "core:fmt"
import ma "vendor:miniaudio"
import "core:math/rand"

AudioEngine :: struct {
    sample_rate: u32,
    setting_change: bool,
    channels: u32,
    frames_per_buffer: u32,
    format: ma.format,

    devices: [dynamic]ma.device_info,
    device: ma.device,
    device_config: ma.device_config,

    resource_manager_config: ma.resource_manager_config,
    resource_manager: ma.resource_manager,

    engine: ma.engine,
    engine_config: ma.engine_config,

    graph: ^AudioGraph,
    ctx: EngineContext,

    // Nodes
    playhead: ^Playhead,
    metronome: ^MetronomeNode,
    outputBuffer: []f32,
    zeroBuffer: []f32,

    // Methods
    initialize: proc(engine: ^AudioEngine) -> bool,
    uninitialize: proc(engine: ^AudioEngine),
    start: proc(engine: ^AudioEngine) -> bool,
    stop: proc(engine: ^AudioEngine),
    build: proc(engine: ^AudioEngine),
    audioCallback: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frameCount: u32),

}

createAudioEngine :: proc(sample_rate: u32 = 48000, channels: u32 = 2, frames_per_buffer: u32 = 256, format: ma.format = ma.format.f32) -> ^AudioEngine {
    audio_engine := new(AudioEngine)
    audio_engine.sample_rate = sample_rate
    audio_engine.setting_change = true
    audio_engine.channels = channels
    audio_engine.frames_per_buffer = frames_per_buffer
    audio_engine.format = format
    audio_engine.audioCallback = audioEngineAudioCallback

    audio_engine.device_config.sampleRate = sample_rate
    audio_engine.device_config.deviceType = ma.device_type.duplex
    audio_engine.device_config.playback.channels = channels
    audio_engine.device_config.playback.format = format
    audio_engine.device_config.periodSizeInFrames = frames_per_buffer
    audio_engine.device_config.dataCallback = audioEngineAudioCallback
    audio_engine.device_config.pUserData = audio_engine

    audio_engine.resource_manager_config = ma.resource_manager_config_init()
    audio_engine.resource_manager_config.decodedFormat = format
    audio_engine.resource_manager_config.decodedChannels = channels
    audio_engine.resource_manager_config.decodedSampleRate = sample_rate

    audio_engine.engine_config.sampleRate = sample_rate
    audio_engine.engine_config.periodSizeInFrames = frames_per_buffer
    audio_engine.engine_config.channels = channels
    audio_engine.engine_config.pDevice = &audio_engine.device
    audio_engine.engine_config.noAutoStart = true
    audio_engine.engine_config.pResourceManager = &audio_engine.resource_manager

    // Methods
    audio_engine.initialize = initializeAudioEngine
    audio_engine.uninitialize = uninitializeAudioEngine
    audio_engine.start = startAudioEngine
    audio_engine.stop = stopAudioEngine
    audio_engine.build = audioEngineBuild

    // initial nodes
    audio_engine.playhead = createPlayhead(f64(sample_rate))
    audio_engine.graph = createAudioGraph()

    return audio_engine
}

// This is where nodes are created and attached to the engine, and any other setup that needs to happen after the engine is initialized
audioEngineBuild :: proc(audio_engine: ^AudioEngine) {
    audio_engine.metronome = createMetronomeNode(audio_engine)
}
clearOutputBuffer :: proc(audio_engine: ^AudioEngine) {
    copy(audio_engine.outputBuffer, audio_engine.zeroBuffer)
}

audioEngineAudioCallback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frameCount: u32) {
    context = runtime.default_context()
    context.random_generator = crypto.random_generator()
    audio_engine := cast(^AudioEngine)device.pUserData
    graph := audio_engine.graph

    if audio_engine.playhead != nil {
        audio_engine.playhead->process(frameCount)
    }

    clearOutputBuffer(audio_engine)

    outSamples := cast([^]f32)output
    // ma.engine_read_pcm_frames(&audio_engine.engine, output, u64(frameCount), nil)
    if audio_engine.setting_change {
        graph->prepare(audio_engine.ctx)
        audio_engine.setting_change = false
    }
    graph->process(audio_engine.ctx, audio_engine.outputBuffer, frameCount)
    for i in 0 ..< frameCount * audio_engine.channels {
        outSamples[i] = audio_engine.outputBuffer[i]
    }
    audio_engine.ctx.render_quantum += 1
    
    

}


initializeAudioEngine :: proc(audio_engine: ^AudioEngine) -> bool {
    // Resize outputBuffer

    fmt.printfln("resize output buffer to %d frames", audio_engine.frames_per_buffer)
    audio_engine.outputBuffer = make([]f32, audio_engine.frames_per_buffer * audio_engine.channels)
    audio_engine.zeroBuffer = make([]f32, audio_engine.frames_per_buffer * audio_engine.channels)

    fmt.printfln("Initializing audio graph")
    audio_engine.graph->initialize()

    if res := ma.resource_manager_init(&audio_engine.resource_manager_config, &audio_engine.resource_manager); res != ma.result.SUCCESS {
        fmt.printfln("Failed to initialize audio resource manager: %s", res)
        return false
    } else {
        fmt.println("Audio resource manager initialized successfully")
    }
    
    fmt.println("Resource Manager initialized with config:")
    audio_engine.engine_config.pResourceManager = &audio_engine.resource_manager
    // mem.set(&audio_engine.outputBuffer, 0, len(audio_engine.outputBuffer))
    
    // Build graph context
    audio_engine.ctx = EngineContext{
        sample_rate = f64(audio_engine.sample_rate),
        channels = audio_engine.channels,
        frames_per_buffer = audio_engine.frames_per_buffer,
        render_quantum = 0,
    }


    if res := ma.device_init(nil, &audio_engine.device_config, &audio_engine.device); res != ma.result.SUCCESS {
        fmt.printfln("Failed to initialize audio device: %s", res)
        return false
    } else {
        fmt.println("Audio device initialized successfully")
        // print device info for debugging
    }
    
    
    if res := ma.engine_init(&audio_engine.engine_config, &audio_engine.engine); res != ma.result.SUCCESS {
        fmt.printfln("Failed to initialize audio engine: %s", res)
        return false
    } else {
        fmt.println("Audio engine initialized successfully")
    }

    audio_engine.metronome = createMetronomeNode(audio_engine)
    return true
}

uninitializeAudioEngine :: proc(audio_engine: ^AudioEngine) {
    ma.engine_uninit(&audio_engine.engine)
    ma.device_uninit(&audio_engine.device)
    ma.resource_manager_uninit(&audio_engine.resource_manager)
}

startAudioEngine :: proc(audio_engine: ^AudioEngine) -> bool {

    if res := ma.engine_start(&audio_engine.engine); res != ma.result.SUCCESS {
        fmt.printfln("Failed to start audio engine: %s", res)
        return false
    } else {
        fmt.println("Audio engine started successfully")
    }
    return true
}

stopAudioEngine :: proc(audio_engine: ^AudioEngine) {
    ma.engine_stop(&audio_engine.engine)

}