package main

import "core:time"
import "hardware_devices"
import daw_pkg "daw"

main :: proc() {

    daw := daw_pkg.createDAW()
    daw->initialize()
    mpc := hardware_devices.createMPCStudioBlack()
    daw->addControlSurface(mpc)
    defer daw->unInitialzeDaw()
    
    mpc.display->run()

    

}






