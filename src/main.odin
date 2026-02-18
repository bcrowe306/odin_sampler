package main

import "core:math"
import "core:fmt"
import "midi"
import ma "vendor:miniaudio"

import cairo "cairo"
import "hardware_devices"
import "control_surface"
import "daw"
import "audio"
import "app"

import clay "../lib/clay-odin"

FPS : i32 = 60

knob1, knob2, knob3, knob4 : ^cairo.KnobWidget
value : f64 = 0.
// 90 2C
mpc: ^hardware_devices.MPC_Studio_Black
audio_engine: ^audio.AudioEngine
perc : ma.sound


onMidiInput :: proc(msg: ^midi.ShortMessage) {

    if msg->getMessageType() == midi.CONTROL_CHANGE && msg.data1 == 0x10 {
        if msg.data2 < 64 {
            value = clamp(value + 0.01, 0.0, 1.0)
        }
        else if msg.data2 >= 64 {
            value = clamp(value - 0.01, 0.0, 1.0)
        }
        knob1->setValue(value)
    }
    if msg->getMessageType() == midi.CONTROL_CHANGE && msg.data1 == 0x11 {
        if msg.data2 < 64 {
            value = clamp(value + 0.01, 0.0, 1.0)
        }
        else if msg.data2 >= 64 {
            value = clamp(value - 0.01, 0.0, 1.0)
        }
        knob2->setValue(value)
    }
    if msg->getMessageType() == midi.CONTROL_CHANGE && msg.data1 == 0x12 {
        if msg.data2 < 64 {
            value = clamp(value + 0.01, 0.0, 1.0)
        }
        else if msg.data2 >= 64 {
            value = clamp(value - 0.01, 0.0, 1.0)
        }
        knob3->setValue(value)
    }
    // Encoder 4
    if msg->getMessageType() == midi.CONTROL_CHANGE && msg.data1 == 0x13 {
        // use bit mask the encoder value. Follows normal midi Relative 2 (N2) Behavior
        sign := (msg.data2 >> 6) & 1
        magnitude := int(msg.data2 & 0x3F)
        if sign == 1 {
            magnitude = magnitude - 64
        }
        
    }

    // Pad 1
    if msg.status == u8(0x99) && msg.data1 == 0x25 {
        ma.sound_seek_to_pcm_frame(&perc, 0)
        ma.sound_start(&perc)
    }

    // Play
    if msg.status == u8(0x90) && msg.data1 == 0x52 && msg.data2 > 0 {
        audio_engine.playhead->setPlayheadState(audio.PlayheadState.Playing)
    }

    // Stop
    if msg.status == u8(0x90) && msg.data1 == 0x51 && msg.data2 > 0 {
        audio_engine.playhead->setPlayheadState(audio.PlayheadState.Stopped)
    }


}

main :: proc() {

    daw := daw.DAW{}
    audio_engine = audio.createAudioEngine()
    mpc = hardware_devices.createMPCStudioBlack(&daw)

    // Audio initialization
    audio_engine->initialize()
    
    if res := ma.sound_init_from_file(&audio_engine.engine, "test.wav", {.NO_SPATIALIZATION}, nil, nil, &perc); res != ma.result.SUCCESS {
        fmt.printfln("Failed to load sound: %s", res)
        return
    }
    
    audio_engine->start()
    audio_engine.playhead->setTempo(120)
    // audio_engine.playhead->setPlayheadState(audio.PlayheadState.Playing)
    
    app.signalConnect(audio_engine.playhead.tick_signal, proc(value: audio.TickEvent, user_data: rawptr) {
        if value.playhead_state != audio.PlayheadState.Playing {
            return // Only emit tick events when playing
        }
        if value.tick_type == audio.TickType.Beat {
            fmt.println("Beat tick")
        }
        else if value.tick_type == audio.TickType.Bar {
            fmt.println("Bar tick")
        }
    }, nil)
   


    // Hardware initialization and main loop
    mpc->initialize()
    mpc->device->subscribe(onMidiInput)
    ma.sound_start(&perc)
    defer mpc->deInitialize()

    
    mpc.display->run()

    audio_engine->stop()
    audio_engine->uninitialize()
    

}






