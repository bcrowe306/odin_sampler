package main

import "core:fmt"
import "hardware_devices"
import daw_pkg "daw"
import "core:math"
file_path: string = "test.wav"
wave_data : ma.resource_manager_data_source
frames_counter : u64 = 0


import ma "vendor:miniaudio"

main :: proc() {
    
    daw := daw_pkg.createDAW()
    daw->initialize()
    mpc := hardware_devices.createMPCStudioBlack()
    daw->addControlSurface(mpc)
    defer daw->unInitialzeDaw()


    f :ma.resource_manager_flags = {.NON_BLOCKING}
    if res := ma.resource_manager_data_source_init(&daw.audio_engine.resource_manager, fmt.ctprint(file_path), 1, nil, &wave_data); res != ma.result.SUCCESS {
        fmt.printfln("Failed to load audio file: ", file_path)
        return
    } else {
        fmt.printfln("Audio file loaded successfully: ", file_path)
    }
    ma.resource_manager_data_source_set_looping(&wave_data, true)

    node220 :=daw_pkg.createAudioNode()
    node220.onProcess  = proc(node_ptr: rawptr, ctx: daw_pkg.EngineContext, buffer: []f32, frames: u32) {
        // Simple test node that generates a sine wave at 440Hz
        frequency :f32= 220.0
        frames_read: u64 = 0
        ma.resource_manager_data_source_read_pcm_frames(&wave_data, &buffer[0], u64(frames), &frames_read)
        fmt.printfln("Read %d frames from resource manager data source", frames_read)
        
    }
    node220.name = "Sine Oscillator"
    daw.audio_engine.graph->addNode(node220)
    daw.audio_engine.graph->connect(node220, daw_pkg.getGraphEndpoint(daw.audio_engine.graph))





    

    mpc.display->run()

    

}






