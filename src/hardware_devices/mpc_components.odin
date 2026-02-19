package hardware_devices

import "core:fmt"
import daw_pkg "../daw"
import "../app"

createMPCStudioBlackComponents :: proc(mpc: ^MPC_Studio_Black) {
    using daw_pkg
    device_page_component := createComponent("device_page")
    pads := createPadsControl()
    pads.name = "pads"
    device_page_component->addControl(pads, "pads")
    append(&mpc.control_surface.components, cast(rawptr)device_page_component)

    device_page_component.onActivate = proc(ptr: rawptr) {
        fmt.printfln("Device page activated")
        dpc := cast(^Component)ptr
        pads := cast(^PadsControl)dpc.controls_map["pads"]
        daw := pads.daw
        app.signalConnect(daw.tracks.onTrackSelected, proc(index: int, ptr: rawptr) {
            pads := cast(^PadsControl)ptr
            for pad_index, track_index in pads.pads_map {
                
                if track_index == index {
                    fmt.printfln("Track %d selected, activating pad %d", index, pad_index)
                    pads->setPadColor(int(track_index), 7) // Set pad color to red for the selected track
                } else {
                    pads->setPadColor(int(track_index), 0)
                }
            }
        }, cast(rawptr)pads)

         
     }

    

}