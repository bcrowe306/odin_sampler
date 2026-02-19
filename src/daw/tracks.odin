package daw

import "core:fmt"
import "../app"
MAX_TRACKS :: 64

Tracks :: struct {
    tracks : [dynamic]^Track,
    selected_track: ^Track,
    selected_track_index: int,

    selectTrackByIndex: proc(tracks_ptr: ^Tracks, index: int),
    selectTrack: proc(tracks_ptr: ^Tracks, track_ptr: ^Track),
    selectTrackByName: proc(tracks_ptr: ^Tracks, name: string),
    addTrack: proc(tracks_ptr: ^Tracks, track: ^Track),
    removeTrack: proc(tracks_ptr: ^Tracks, index: int),
    nextTrack: proc(tracks_ptr: ^Tracks),
    previousTrack: proc(tracks_ptr: ^Tracks),
    
    // Signals
    onTrackSelected: ^app.Signal(int)
}

createTracks :: proc() -> Tracks {
    tracks := Tracks{}
    reserve(&tracks.tracks, MAX_TRACKS)
    tracks.onTrackSelected = app.createSignal(int)
    tracks.selectTrackByIndex = selectTrackByIndex
    tracks.selectTrack = selectTrack
    tracks.addTrack = addTrack
    tracks.removeTrack = removeTrack
    tracks.nextTrack = nextTrack
    tracks.previousTrack = previousTrack
    tracks.selectTrackByName = selectTrackByName
    for i in 0..<MAX_TRACKS {
        t := createTrack(fmt.tprintf("Track %d", i + 1))
        tracks->addTrack(t)
    }
    tracks->selectTrackByIndex(0)

    return tracks
}

selectTrackByIndex :: proc(tracks: ^Tracks, index: int) {
    if index < 0 || index >= len(tracks.tracks) {
        return
    }
    tracks.selected_track = tracks.tracks[index]
    tracks.selected_track_index = index
    app.signalEmit(tracks.onTrackSelected, index)
}

addTrack :: proc(tracks: ^Tracks, track: ^Track) {
    if len(tracks.tracks) >= MAX_TRACKS {
        return
    }
    if track == nil {
        return
    }
    if track.name == "" {
        track.name = fmt.tprintf("Track %d", len(tracks.tracks) + 1)
    }
    append(&tracks.tracks, track)
    tracks.selectTrackByIndex(tracks, len(tracks.tracks) - 1)
}

removeTrack :: proc(tracks: ^Tracks, index: int) {
    if index < 0 || index >= len(tracks.tracks) {
        return
    }
    ordered_remove(&tracks.tracks, index)
}

nextTrack :: proc(tracks: ^Tracks) {
    if len(tracks.tracks) == 0 {
        return
    }
    new_index := (tracks.selected_track_index + 1) % len(tracks.tracks)
    tracks.selectTrackByIndex(tracks, new_index)
}

previousTrack :: proc(tracks: ^Tracks) {
    if len(tracks.tracks) == 0 {
        return
    }
    new_index := (tracks.selected_track_index - 1 + len(tracks.tracks)) % len(tracks.tracks)
    tracks.selectTrackByIndex(tracks, new_index)
}

selectTrack :: proc(tracks: ^Tracks, track: ^Track) {
    for t, index in tracks.tracks {
        if t == track {
            tracks.selectTrackByIndex(tracks, index)
            return
        }
    }
}

selectTrackByName :: proc(tracks: ^Tracks, name: string) {
    for t, index in tracks.tracks {
        if t.name == name {
            tracks.selectTrackByIndex(tracks, index)
            return
        }
    }
}
