package daw

Transport :: struct {
    daw_ptr: ^DAW,
    setTempo: proc(transport: ^Transport, tempo: f64),
    getTempo: proc(transport: ^Transport) -> f64,
    setSongPosition: proc(transport: ^Transport, position: SongPosition),
    getSongPosition: proc(transport: ^Transport) -> SongPosition,
    play: proc(transport: ^Transport),
    stop: proc(transport: ^Transport),
    togglePlay: proc(transport: ^Transport),
    toggleLoop: proc(transport: ^Transport),
    isPlaying: proc(transport: ^Transport) -> bool,
    isLooping: proc(transport: ^Transport) -> bool,
    setPrecount: proc(transport: ^Transport, precount: u32),
    getPrecount: proc(transport: ^Transport) -> u32,
    setMetronomeEnabled: proc(transport: ^Transport, enabled: bool),
    isMetronomeEnabled: proc(transport: ^Transport) -> bool,
    toggleMetronome: proc(transport: ^Transport),
}

createTransport :: proc(daw: ^DAW) -> Transport {
    return Transport{
        daw_ptr = daw,
        setTempo = transportSetTempo,
        getTempo = transportGetTempo,
        setSongPosition = transportSetSongPosition,
        getSongPosition = transportGetSongPosition,
        play = transportPlay,
        stop = transportStop,
        togglePlay = transportTogglePlay,
        toggleLoop = transportToggleLoop,
        isPlaying = transportIsPlaying,
        isLooping = transportIsLooping,
        setPrecount = transportSetPrecount,
        getPrecount = transportGetPrecount,
        setMetronomeEnabled = transportSetMetronomeEnabled,
        isMetronomeEnabled = transportIsMetronomeEnabled,
        toggleMetronome = transportToggleMetronome,
    }
}   

transportSetTempo :: proc(transport: ^Transport, tempo: f64) {
    playhead := transport.daw_ptr.audio_engine.playhead
    playhead->setTempo(tempo)
}

transportGetTempo :: proc(transport: ^Transport) -> f64 {
    playhead := transport.daw_ptr.audio_engine.playhead
    return playhead.tempo

}

transportSetSongPosition :: proc(transport: ^Transport, position: SongPosition) {
    playhead := transport.daw_ptr.audio_engine.playhead
    // TODO: Implement this
}

transportPlay :: proc(transport: ^Transport) {
    playhead := transport.daw_ptr.audio_engine.playhead
    playhead->setPlayheadState(PlayheadState.Playing)
}

transportStop :: proc(transport: ^Transport) {
    playhead := transport.daw_ptr.audio_engine.playhead
    playhead->setPlayheadState(PlayheadState.Stopped)
}

transportTogglePlay :: proc(transport: ^Transport) {
    playhead := transport.daw_ptr.audio_engine.playhead
    if playhead.playhead_state == PlayheadState.Playing {
        playhead->setPlayheadState(PlayheadState.Stopped)
    } else {
        playhead->setPlayheadState(PlayheadState.Playing)
    }
}

transportToggleLoop :: proc(transport: ^Transport) {
    playhead := transport.daw_ptr.audio_engine.playhead
    playhead->setLooping(!playhead.looping)
}

transportIsPlaying :: proc(transport: ^Transport) -> bool {
    playhead := transport.daw_ptr.audio_engine.playhead
    return playhead.playhead_state == PlayheadState.Playing || playhead.playhead_state == PlayheadState.Recording
}

transportIsLooping :: proc(transport: ^Transport) -> bool {
    playhead := transport.daw_ptr.audio_engine.playhead
    return playhead.looping
}

transportSetPrecount :: proc(transport: ^Transport, precount: u32) {
    transport.daw_ptr.audio_engine.playhead.precount_bars = precount
}

transportGetPrecount :: proc(transport: ^Transport) -> u32 {
    return transport.daw_ptr.audio_engine.playhead.precount_bars
}

transportSetMetronomeEnabled :: proc(transport: ^Transport, enabled: bool) {
    transport.daw_ptr.metronome.enabled = enabled
}

transportIsMetronomeEnabled :: proc(transport: ^Transport) -> bool {
    return transport.daw_ptr.metronome.enabled
}

transportToggleMetronome :: proc(transport: ^Transport) {
    transport.daw_ptr.metronome.enabled = !transport.daw_ptr.metronome.enabled
}

transportGetSongPosition :: proc(transport: ^Transport) -> SongPosition {
    playhead := transport.daw_ptr.audio_engine.playhead
    return playhead->getSongPosition()
}

