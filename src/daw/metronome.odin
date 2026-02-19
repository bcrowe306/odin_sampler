package daw

MetronomeNode :: struct {
    enabled: bool,
    bar_volume: f64,
    beat_volume: f64,
    subdivision_volume: f64,
    bar_sample: string,
    beat_sample: string,
    subdivision_sample: string,
}

createMetronomeNode :: proc() -> MetronomeNode {
    return MetronomeNode{
        enabled = false,
        bar_volume = 1.0,
        beat_volume = 1.0,
        subdivision_volume = 1.0,
        bar_sample = "metronome_bar.wav",
        beat_sample = "metronome_beat.wav",
        subdivision_sample = "metronome_subdivision.wav",
    }
}