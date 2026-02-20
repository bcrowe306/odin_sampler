package daw
import "core:fmt"
import ma "vendor:miniaudio"

MetronomeNode :: struct {
    enabled: bool,
    engine: ^AudioEngine,
    bar_volume: f64,
    beat_volume: f64,
    subdivision_volume: f64,
    bar_sample: string,
    beat_sample: string,
    subdivision_sample: string,
    metronome_sound: ma.sound,
}

createMetronomeNode :: proc(audio_engine: ^AudioEngine) -> ^MetronomeNode {
    metronome := new(MetronomeNode)
    metronome.enabled = true
    metronome.bar_volume = 1.0
    metronome.beat_volume = 0.8
    metronome.subdivision_volume = 0.5
    metronome.bar_sample = "test.wav"
    metronome.engine = audio_engine
    if res := ma.sound_init_from_file(&audio_engine.engine, fmt.ctprint(metronome.bar_sample), nil, nil, nil, &metronome.metronome_sound); res != ma.result.SUCCESS {
        fmt.println("Failed to load metronome bar sample: ", metronome.bar_sample)
    }
    // ma.node_attach_output_bus(cast(^ma.node)&metronome.metronome_sound, 0, ma.engine_get_endpoint(&audio_engine.engine), 0)

    audio_engine.playhead.onMetronomeTick->connect(proc(data: any, user_data: rawptr) {
        event := data.(TickEvent)
        metronome := cast(^MetronomeNode)user_data
        
   
        if !metronome.enabled {
            return
        }
        #partial switch event.tick_type {
            case .Beat:
                fmt.printfln("Tick: %s, Beat: %d", event.tick_type, event.song_position.beat)

            case .Bar:
                fmt.printfln("Tick: %s, Bar: %d", event.tick_type, event.song_position.bar)
        }
    }, audio_engine)
    
    
    
    
    return metronome
}