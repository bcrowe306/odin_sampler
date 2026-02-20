package main

import "core:fmt"
import "hardware_devices"
import daw_pkg "daw"


import ma "vendor:miniaudio"

main :: proc() {
    
    daw := daw_pkg.createDAW()
    daw->initialize()
    mpc := hardware_devices.createMPCStudioBlack()
    daw->addControlSurface(mpc)
    defer daw->unInitialzeDaw()

    node220 :=daw_pkg.createSampleNode(daw, "test.wav")
    
    node220.name = "Sine Oscillator"
    daw.audio_engine.graph->addNode(node220)
    daw.audio_engine.graph->connect(node220, daw_pkg.getGraphEndpoint(daw.audio_engine.graph))





    

    mpc.display->run()

    

}






