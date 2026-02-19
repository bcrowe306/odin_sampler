package daw

import "core:time"
import ma "vendor:miniaudio"
import "base:runtime"
import "core:fmt"
import "../app"


PPQN : f64 = 480


TickType :: enum {
    Tick,
    Beat,
    Bar,
}

TickEvent :: struct {
    tick_type: TickType,
    tick: u64,
    playhead_state: PlayheadState,
    song_position: SongPosition,
}

PlayheadStateEvent :: struct {
    old_state: PlayheadState,
    new_state: PlayheadState,
}


PlayheadState :: enum {
    Stopped,
    Precount,
    Recording,
    Playing,
    Paused,
}

SongPosition :: struct {
    bar: u32,
    beat: u32,
    sixteenth: u32,
    tick: u32,
    frame: f64,
    tempo: f64,
    time_signature: TimeSignature,
    toShortString: proc(pos: SongPosition) -> string,
    toTimeString: proc(pos: SongPosition) -> string,
}

createSongPosition :: proc() -> SongPosition {
    pos := SongPosition{
        bar = 0,
        beat = 0,
        sixteenth = 0,
        tick = 0,
        frame = 0,
        tempo = 120.0,
        time_signature = TimeSignature{numerator = 4, denominator = 4},
    }
    pos.toShortString = songPositionToShortString
    pos.toTimeString = songPositionToTimeString
    return pos
}
songPositionToShortString :: proc(pos: SongPosition) -> string {
    return fmt.tprintf("%d:%d:%d:%d", pos.bar, pos.beat, pos.sixteenth, pos.tick)
}

songPositionToTimeString :: proc(pos: SongPosition) -> string {
    // total_seconds := (f64(pos.bar) * f64(pos.time_signature.numerator) + f64(pos.beat) + f64(pos.sixteenth) / 4.0 + f64(pos.tick) / pos.ticks_per_beat) * (60.0 / pos.tempo)
    // minutes := u32(total_seconds / 60)
    // seconds := u32(total_seconds) % 60
    // milliseconds := u32((total_seconds - f64(u32(total_seconds))) * 1000)
    return fmt.tprintf("%02d:%02d.%03d", 1,2,3) // Placeholder until I implement the actual time calculation
}



playheadProcess :: proc (playhead: ^Playhead, frame_count: u32) {
    context = runtime.default_context()
    switch playhead.playhead_state {
        case .Playing:
            playheadPlayingState(playhead, frame_count)
        case .Precount:
            playheadPrecountState(playhead, frame_count)
        case .Stopped:
            playheadStoppedState(playhead, frame_count)
        case .Paused:
            playheadPausedState(playhead, frame_count)
        case .Recording:
            playheadRecordingState(playhead, frame_count)
    }

}

TimeSignature :: struct {
    numerator: u32,
    denominator: u32,
}


Playhead :: struct {
    playhead_state: PlayheadState,
    tempo: f64,
    ppqn: f64,
    samples_per_tick: f64,
    sample_rate: f64,
    precount_bars: u32,
    precount_enabled: bool,
    return_to_start_on_stop: bool,
    song_position: SongPosition,
    ticks_per_beat: f64,
    ticks_per_bar: f64,
    tick_signal: ^app.Signal(TickEvent),
    state_signal: ^app.Signal(PlayheadStateEvent),
    looping: bool,
    loop_start_tick: u32,
    loop_end_tick: u32,
    process: proc(playhead: ^Playhead, frame_count: u32),

    // Methods
    setPlayheadState: proc(playhead: ^Playhead, new_state: PlayheadState),
    setTempo: proc(playhead: ^Playhead, tempo: f64),
    setLooping: proc(playhead: ^Playhead, looping: bool),
    setLoopStart: proc(playhead: ^Playhead, tick: u32),
    setLoopEnd: proc(playhead: ^Playhead, tick: u32),
    setLoopPoints: proc(playhead: ^Playhead, start_tick: u32, end_tick: u32),
}

createPlayhead :: proc(sample_rate: f64, tempo: f64 = 100) -> ^Playhead {
    playhead := new(Playhead)
    playhead.playhead_state = .Stopped
    playhead.ppqn = PPQN
    playhead.sample_rate = sample_rate
    
    playhead.precount_bars = 1
    playhead.precount_enabled = true
    playhead.return_to_start_on_stop = true
    
    setTempo(playhead, tempo)
    playhead.tick_signal = app.createSignal(TickEvent)
    playhead.state_signal = app.createSignal(PlayheadStateEvent)
    playhead.process = playheadProcess
    playhead.song_position = createSongPosition()

    // Methods
    playhead.setPlayheadState = setPlayheadState
    playhead.setTempo = setTempo
    playhead.setLooping = setPlayheadLooping
    playhead.setLoopStart = setPlayheadLoopStart
    playhead.setLoopEnd = setPlayheadLoopEnd
    playhead.setLoopPoints = setPlayheadLoopPoints
    return playhead
}

setPlayheadLooping :: proc(playhead: ^Playhead, looping: bool) {
    playhead.looping = looping
}

setPlayheadLoopStart :: proc(playhead: ^Playhead, tick: u32) {
    playhead.loop_start_tick = tick
}

setPlayheadLoopEnd :: proc(playhead: ^Playhead, tick: u32) {
    playhead.loop_end_tick = tick
}
setPlayheadLoopPoints :: proc(playhead: ^Playhead, start_tick: u32, end_tick: u32) {
    playhead.loop_start_tick = start_tick
    playhead.loop_end_tick = end_tick
}

calculateSongPosition :: proc(playhead: ^Playhead) {


    playhead.song_position.bar = u32(playhead.song_position.tick / u32(playhead.ticks_per_bar))
    playhead.song_position.beat = u32((playhead.song_position.tick % u32(playhead.ticks_per_bar)) / u32(playhead.ticks_per_beat))
    playhead.song_position.sixteenth = u32((playhead.song_position.tick % u32(playhead.ticks_per_beat)) / u32(playhead.ticks_per_beat / 4))
    playhead.song_position.tick = u32(playhead.song_position.tick % u32(playhead.ticks_per_beat / 4))
    playhead.song_position.frame = playhead.song_position.frame
    playhead.song_position.tempo = playhead.tempo
    playhead.song_position.time_signature = playhead.song_position.time_signature

}

emitTickEvent :: proc(playhead: ^Playhead, tick_type: TickType) {
    event := TickEvent{
        tick_type = tick_type,
        playhead_state = playhead.playhead_state,
        song_position = playhead.song_position,
    }
    if playhead.tick_signal != nil {
        app.signalEmit(playhead.tick_signal, event)
    }
}

ticksPerBeat :: proc(playhead: ^Playhead) -> f64 {
    return playhead.ppqn * (4.0 / f64(playhead.song_position.time_signature.denominator))
}

isBeat :: proc(playhead: ^Playhead, tick: u32) -> bool {
    return tick % u32(ticksPerBeat(playhead)) == 0
}

ticksPerBar :: proc(playhead: ^Playhead) -> f64 {
    return ticksPerBeat(playhead) * f64(playhead.song_position.time_signature.numerator)
}

isBar :: proc(playhead: ^Playhead, tick: u32) -> bool {
    return tick % u32(ticksPerBar(playhead)) == 0
}

calculateSamplesPerTick :: proc(playhead: ^Playhead) {
    playhead.samples_per_tick = (60.0 / playhead.tempo) * (playhead.sample_rate / playhead.ppqn)
}

setTempo :: proc(playhead: ^Playhead, tempo: f64) {
    playhead.tempo = tempo
    calculateSamplesPerTick(playhead)
    playhead.ticks_per_beat = ticksPerBeat(playhead)
    playhead.ticks_per_bar = ticksPerBar(playhead)
}

processTick :: proc(playhead: ^Playhead) -> bool {
    t := playhead.song_position.frame >= playhead.samples_per_tick
    if t {
        if isBar(playhead, playhead.song_position.tick) {
            emitTickEvent(playhead, TickType.Bar)
        } else if isBeat(playhead, playhead.song_position.tick) {
            emitTickEvent(playhead, TickType.Beat)
        } else {
            emitTickEvent(playhead, TickType.Tick)
        }

        playhead.song_position.frame -= playhead.samples_per_tick

        // Only advance the tick if we're in a state that should be advancing. The tick is the song position, so it shouldn't advance if we're stopped or paused
        if playhead.playhead_state == .Precount || playhead.playhead_state == .Playing || playhead.playhead_state == .Recording {
            playhead.song_position.tick += 1
        }
        
        // The tick_counter keeps ticking even when playhead is paused or stopped.
        // This helps with syncing time-based effects when not playing, and also allows for the playhead to emit tick events while paused or stopped.
        
        playhead.song_position.frame += 1
        
    }
    return t
}


playheadPlayingState :: proc(playhead: ^Playhead, frame_count: u32)  {
    for frame in 0..<frame_count {
        processTick(playhead)
        playhead.song_position.frame += 1
    }
}

playheadPrecountState :: proc(playhead: ^Playhead, frame_count: u32)  {
    for frame in 0..<frame_count {
        processTick(playhead)
        if playhead.song_position.tick >= u32(playhead.precount_bars) * u32(playhead.ticks_per_bar) {
            setPlayheadState(playhead, PlayheadState.Recording)
            break
        }
        playhead.song_position.frame += 1
    }
}

playheadStoppedState :: proc(playhead: ^Playhead, frame_count: u32)  {
    playhead.song_position.frame = 0
    playhead.song_position.tick = 0
    for frame in 0..<frame_count {
        if processTick(playhead) {
            
        }
        playhead.song_position.frame += 1
    }
}

playheadPausedState :: proc(playhead: ^Playhead, frame_count: u32)  {
    playhead.song_position.frame = 0
    playhead.song_position.tick = 0
    for frame in 0..<frame_count {
        if processTick(playhead) {
            
        }
        playhead.song_position.frame += 1
    }
}

playheadRecordingState :: proc(playhead: ^Playhead, frame_count: u32)  {
    for frame in 0..<frame_count {
        if processTick(playhead) {
            
        }
        playhead.song_position.frame += 1
        playhead.song_position.tick += 1
    }
}



setPlayheadState :: proc(playhead: ^Playhead, new_state: PlayheadState) {
    old_state := playhead.playhead_state
    switch new_state {
        case .Playing:
            if old_state == .Precount {
                playhead.song_position.tick = 0
                playhead.song_position.frame = 0
            }
            playhead.playhead_state = new_state
            app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                old_state = old_state,
                new_state = new_state,
            })
        case .Precount:
            if old_state == .Stopped {
                playhead.song_position.tick = 0
                playhead.song_position.frame = 0
                playhead.playhead_state = new_state
                app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                    old_state = old_state,
                    new_state = new_state,
                })
            }
        case .Stopped:
            if old_state == .Playing || old_state == .Recording {
                if playhead.return_to_start_on_stop {
                    playhead.song_position.tick = 0
                    playhead.song_position.frame = 0
                }
                playhead.playhead_state = new_state
                app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                old_state = old_state,
                new_state = new_state,
            })
            }
            else if old_state == .Precount {
                playhead.song_position.tick = 0
                playhead.song_position.frame = 0
                playhead.playhead_state = new_state
                app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                    old_state = old_state,
                    new_state = new_state,
                })
            }
            else if old_state == .Paused {
                playhead.song_position.tick = 0
                playhead.song_position.frame = 0
                playhead.playhead_state = new_state
                app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                    old_state = old_state,
                    new_state = new_state,
                })
            }
        case .Paused:
            if old_state == .Playing || old_state == .Recording {
                playhead.playhead_state = new_state
                app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                    old_state = old_state,
                    new_state = new_state,
                })
            }
        case .Recording:
            if old_state == .Precount {
                playhead.song_position.tick = 0
                playhead.song_position.frame = 0
                playhead.playhead_state = new_state
                app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                    old_state = old_state,
                    new_state = new_state,
                })
            }
            else if old_state == .Playing {
                playhead.playhead_state = new_state
                app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                    old_state = old_state,
                    new_state = new_state,
                })
            }
            else if old_state == .Stopped {
                if playhead.precount_enabled {
                    playhead.song_position.tick = 0
                    playhead.song_position.frame = 0
                    playhead.playhead_state = PlayheadState.Precount
                    app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                        old_state = old_state,
                        new_state = PlayheadState.Precount,
                    })
                }
                else {
                    playhead.song_position.tick = 0
                    playhead.song_position.frame = 0
                    playhead.playhead_state = new_state
                    app.signalEmit(playhead.state_signal, PlayheadStateEvent{
                        old_state = old_state,
                        new_state = new_state,
                    })
                }
            }
    }
}