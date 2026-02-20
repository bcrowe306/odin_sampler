package daw
import ma "vendor:miniaudio"
import "core:fmt"

SampleNodeState :: enum {
    Stopped,
    Playing,
    Paused,
    Loading,
    Error,
}
SampleNode :: struct {
    using node: AudioNode,
    cursor: u64,
    start: u64,
    length: u64,
    end: u64,
    looping: bool,
    reversed: bool,
    state: SampleNodeState,
    data_source: ma.resource_manager_data_source,
    file_path: string,
    
    // Methods
    play: proc(node_ptr: rawptr),
    stop: proc(node_ptr: rawptr),
    togglePause: proc(node_ptr: rawptr),
}

createSampleNode :: proc(daw: ^DAW, file_path: string) -> ^SampleNode {
    node := new(SampleNode)
    configureNode(cast(^AudioNode)node)
    node.file_path = file_path
    node.start = 0
    node.cursor = 0
    node.length = 0
    node.end = 0
    node.looping = true
    node.reversed = false

    // Load audio file using miniaudio resource manager. ASYNC and DECODE flags are set so that it doesn't block the audio thread and we can poll the loading state in the process callback
    f :ma.resource_manager_data_source_flags = {.DECODE, .ASYNC}
    if res := ma.resource_manager_data_source_init(&daw.audio_engine.resource_manager, fmt.ctprint(file_path), 1, nil, &node.data_source); res != ma.result.SUCCESS {
        fmt.printfln("Error loading file %s: Error %s", file_path, res)
        node.state = SampleNodeState.Error
    } else {
        fmt.printfln("Audio file loading started: %s", file_path)
        node.state = SampleNodeState.Loading
    }
    // methods
    node.play = sampleNodePlay
    node.stop = sampleNodeStop
    node.togglePause = sampleNodeTogglePause
    node.onProcess = sampleNodeProcess
    return node
}


sampleNodeProcess :: proc(node_ptr: rawptr, ctx: EngineContext, buffer: []f32, frames: u32) {

    node := cast(^SampleNode)node_ptr

    // Poll loading state
    if node.state == SampleNodeState.Loading {
        res := ma.resource_manager_data_source_result(&node.data_source)
        #partial switch res {
            case .SUCCESS:
                // get length and set end point
                ma.resource_manager_data_source_get_length_in_pcm_frames(&node.data_source, &node.length)
                fmt.printfln("Audio file %s loaded successfully: %d frames", node.file_path, node.length)
                setEnd(node_ptr, node.end)
                setStart(node_ptr, node.start)
                ma.resource_manager_data_source_seek_to_pcm_frame(&node.data_source, node.start)
                node.state = SampleNodeState.Playing
            case .BUSY:
                // Still loading, do nothing
            case:
                fmt.printfln("Error loading audio file %s: %s", node.file_path, res)
                node.state = SampleNodeState.Error
        }
    }


    if node.state != SampleNodeState.Playing {
        outputZeroBuffer(node_ptr, ctx, buffer, frames)
        return
    }
    frames_read: u64 = 0
    cursor: u64 = 0

    if node.state == SampleNodeState.Playing {
        // read frames
        ma.resource_manager_data_source_read_pcm_frames(&node.data_source, &buffer[0], u64(frames), &frames_read)
    }
    
    // get cursor
    ma.resource_manager_data_source_get_cursor_in_pcm_frames(&node.data_source, &cursor)
    node.cursor = cursor + frames_read
    if node.cursor >= node.end {
        if node.looping {
            ma.resource_manager_data_source_seek_to_pcm_frame(&node.data_source, node.start)
        } else {
            node.state = SampleNodeState.Stopped
            ma.resource_manager_data_source_seek_to_pcm_frame(&node.data_source, node.start)
        }
    }
}

sampleNodePlay :: proc(node_ptr: rawptr) {
    node := cast(^SampleNode)node_ptr
    ma.resource_manager_data_source_seek_to_pcm_frame(&node.data_source, node.start)
    node.state = SampleNodeState.Playing
}

sampleNodeStop :: proc(node_ptr: rawptr) {
    node := cast(^SampleNode)node_ptr
    node.state = SampleNodeState.Stopped
    ma.resource_manager_data_source_seek_to_pcm_frame(&node.data_source, node.start)
    
}

sampleNodeTogglePause :: proc(node_ptr: rawptr) {
    node := cast(^SampleNode)node_ptr
    if node.state == SampleNodeState.Playing {
        node.state = SampleNodeState.Paused
    } else if node.state == SampleNodeState.Paused {
        node.state = SampleNodeState.Playing
    }
}

setStart :: proc(node_ptr: rawptr, start_frame: u64) {
    node := cast(^SampleNode)node_ptr
    node.start = clamp(start_frame, 0, node.end - 1)
}

setEnd :: proc(node_ptr: rawptr, end_frame: u64) {
    node := cast(^SampleNode)node_ptr
    if end_frame == 0 {
        node.end = node.length
    }
    node.end = clamp(end_frame, node.start + 1, node.length)
}
