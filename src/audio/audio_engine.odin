package audio 

import "base:runtime"
import "core:fmt"
import ma "vendor:miniaudio"

AudioEngine :: struct {
    sample_rate: u32,
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

    playhead: ^Playhead,

    // Methods
    initialize: proc(engine: ^AudioEngine) -> bool,
    uninitialize: proc(engine: ^AudioEngine),
    start: proc(engine: ^AudioEngine) -> bool,
    stop: proc(engine: ^AudioEngine),
    audioCallback: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frameCount: u32),

}

createAudioEngine :: proc(sample_rate: u32 = 48000, channels: u32 = 2, frames_per_buffer: u32 = 256, format: ma.format = ma.format.f32) -> ^AudioEngine {
    audio_engine := new(AudioEngine)
    audio_engine.sample_rate = sample_rate
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

    audio_engine.playhead = createPlayhead(f64(sample_rate))

    // Methods
    audio_engine.initialize = initializeAudioEngine
    audio_engine.uninitialize = uninitializeAudioEngine
    audio_engine.start = startAudioEngine
    audio_engine.stop = stopAudioEngine


    return audio_engine
}


audioEngineAudioCallback :: proc "c" (device: ^ma.device, output: rawptr, input: rawptr, frameCount: u32) {
    context = runtime.default_context()
    audio_engine := cast(^AudioEngine)device.pUserData
    if audio_engine.playhead != nil {
        audio_engine.playhead->process(frameCount)
    }
    ma.engine_read_pcm_frames(&audio_engine.engine, output, u64(frameCount), nil)

}

initializeAudioEngine :: proc(audio_engine: ^AudioEngine) -> bool {
    if res := ma.resource_manager_init(&audio_engine.resource_manager_config, &audio_engine.resource_manager); res != ma.result.SUCCESS {
        fmt.printfln("Failed to initialize audio resource manager: %s", res)
        return false
    }
    audio_engine.engine_config.pResourceManager = &audio_engine.resource_manager


    if res := ma.device_init(nil, &audio_engine.device_config, &audio_engine.device); res != ma.result.SUCCESS {
        fmt.printfln("Failed to initialize audio device: %s", res)
        return false
    }
    
    if res := ma.engine_init(&audio_engine.engine_config, &audio_engine.engine); res != ma.result.SUCCESS {
        fmt.printfln("Failed to initialize audio engine: %s", res)
        return false
    }

    
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
    }
    return true
}

stopAudioEngine :: proc(audio_engine: ^AudioEngine) {
    ma.engine_stop(&audio_engine.engine)

}