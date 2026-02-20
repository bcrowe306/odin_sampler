package hardware_devices

import "core:math"
import "core:math/rand"
import "core:fmt"
import daw_pkg "../daw"
import "../app"

// TODO: Add more convineint way to create and attach controls to components, right now it's a bit clunky and requires a lot of boilerplate code

createMPCStudioBlackComponents :: proc(mpc: ^MPC_Studio_Black) {
    using daw_pkg
    device_page_component := createComponent("device_page")
    pads := createPadsControl()
    pads.name = "pads"
    device_page_component->addControl(pads, "pads")

    play_button := createButtonControl("play_button", 0, auto_cast daw_pkg.MIDI_STATUS.NOTE_ON, auto_cast MPCSB_CONTROL.PLAY_BUTTON)
    device_page_component->addControl(play_button, "play_button")

    stop_button := createButtonControl("stop_button", 0, auto_cast daw_pkg.MIDI_STATUS.NOTE_ON, auto_cast MPCSB_CONTROL.STOP_BUTTON)
    device_page_component->addControl(stop_button, "stop_button")


    append(&mpc.control_surface.components, cast(rawptr)device_page_component)


    device_page_component.onActivate = proc(ptr: rawptr) {
        fmt.printfln("Device page activated")
        dpc := cast(^Component)ptr
        pads := cast(^PadsControl)dpc.controls_map["pads"]
        play_button := cast(^ButtonControl)dpc.controls_map["play_button"]
        stop_button := cast(^ButtonControl)dpc.controls_map["stop_button"]
        daw := pads.daw

        // Connect track selection to pad colors
        app.signalConnect(daw.tracks.onTrackSelected, proc(index_type: any, ptr: rawptr) {
            index := index_type.(int)
            pads := cast(^PadsControl)ptr
            for pad_index, track_index in pads.pads_map {
                
                if track_index == index {
                    pads->setPadColor(int(track_index), 7) // Set pad color to red for the selected track
                } else {
                    pads->setPadColor(int(track_index), 0)
                }
            }
        }, cast(rawptr)pads)


        dpc.addConnection(dpc, pads.onPressed, proc(pad_index_type: any, ptr: rawptr) {
            pad_index := pad_index_type.(int)
            dpc := cast(^Component)ptr
            pads := cast(^PadsControl)dpc.controls_map["pads"]
            track_index := pad_index + pads.page_index * PADS_PER_PAGE
            pads.daw.tracks->selectTrackByIndex(track_index)
        })

        dpc.addConnection(dpc, play_button.onPress, proc(value: any, ptr: rawptr) {
            dpc := cast(^Component)ptr
            play_button := cast(^ButtonControl)dpc.controls_map["play_button"]
                play_button.daw.transport->togglePlay()
        })

        dpc.addConnection(dpc, stop_button.onPress, proc(value: any, ptr: rawptr) {
            dpc := cast(^Component)ptr
            stop_button := cast(^ButtonControl)dpc.controls_map["stop_button"]
            new_node := daw_pkg.createAudioNode()
            daw := stop_button.daw
            new_node.onProcess = proc(node_ptr: rawptr, ctx: daw_pkg.EngineContext, buffer: []f32, frames: u32) {
                for i in 0 ..< frames {
                    for ch in 0 ..< ctx.channels {
                        buffer[i * ctx.channels + ch] += f32(math.lerp(-1.0, 1.0, rand.float64())) * .5
                    }
                }
             }

             new_node.name = "Stop Button Node"
             daw.audio_engine.graph->addNode(new_node)
             daw.audio_engine.graph->connect(new_node, daw_pkg.getGraphEndpoint(daw.audio_engine.graph))
        })
         
     }

}