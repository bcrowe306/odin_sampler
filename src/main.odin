package main

import "core:fmt"
import "midi"
import ma "vendor:miniaudio"

import cairo "cairo"
import "hardware_devices"
import "control_surface"
import "daw"
import "audio"
import "app"


FPS : i32 = 60

knob1, knob2, knob3, knob4 : ^cairo.KnobWidget
value : f64 = 0.
// 90 2C
mpc: ^hardware_devices.MPC_Studio_Black
audio_engine: ^audio.AudioEngine
perc : ma.sound

onMidiInput :: proc(msg: ^midi.ShortMessage) {
    if msg.status == u8(0x90) && msg.data1 == u8(0x2C) && msg.data2 > 0 {
        fmt.println("Switching to Seq Page")
        mpc.display.router->push("seq_page", nil)
    }

    if msg.status == u8(0x90) && msg.data1 == u8(0x2D) && msg.data2 > 0 {
        fmt.println("Switching to Test Page")
        mpc.display.router->push("test_page", nil)
    }



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
    if msg->getMessageType() == midi.CONTROL_CHANGE && msg.data1 == 0x13 {
        if msg.data2 < 64 {
            value = clamp(value + 0.01, 0.0, 1.0)
        }
        else if msg.data2 >= 64 {
            value = clamp(value - 0.01, 0.0, 1.0)
        }
        knob4->setValue(value)
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


    
    f1 := cairo.createFunctionWidget(cairo.rectangle_t{0, 83, 60, 12}, "Sample", 11)
    f2 := cairo.createFunctionWidget(cairo.rectangle_t{60, 83, 60, 12}, "Env", 11)
    f3 := cairo.createFunctionWidget(cairo.rectangle_t{120, 83, 60, 12}, "Filter", 11)
    f4 := cairo.createFunctionWidget(cairo.rectangle_t{180, 83, 60, 12}, "LFO", 11)
    f5 := cairo.createFunctionWidget(cairo.rectangle_t{240, 83, 60, 12}, "Effects", 11)
    f6 := cairo.createFunctionWidget(cairo.rectangle_t{300, 83, 60, 12}, "Track", 11)

    knob_height :f64 = 40
    knob_y:f64 = 40
    knob_width :f64 = 60
    knob1 = cairo.createKnobWidget(cairo.rectangle_t{5, knob_y, knob_width, knob_height}, "Frequency")
    knob2 = cairo.createKnobWidget(cairo.rectangle_t{95, knob_y, knob_width, knob_height}, "Resonance")
    knob3 = cairo.createKnobWidget(cairo.rectangle_t{185, knob_y, knob_width, knob_height}, "Attack")
    knob4 = cairo.createKnobWidget(cairo.rectangle_t{275, knob_y, knob_width, knob_height}, "Decay")

    test_page := cairo.createPageWidget("test_page", cairo.PageUpdateMethod.OnChange)
    seq_page := cairo.createPageWidget("seq_page", cairo.PageUpdateMethod.OnChange)

    test_page->addWidget(knob1)
    test_page->addWidget(knob2)
    test_page->addWidget(knob3)
    test_page->addWidget(knob4)
    test_page->addWidget(f1)
    test_page->addWidget(f2)
    test_page->addWidget(f3)
    test_page->addWidget(f4)
    test_page->addWidget(f5)
    test_page->addWidget(f6)

    seq_page->addWidget(knob1)
    seq_page->addWidget(knob2)
    seq_page->addWidget(knob3)
    seq_page->addWidget(knob4)
  
    
    mpc.display->router->addPage(test_page)
    mpc.display->router->addPage(seq_page)
   

    // Audio initialization
    audio_engine->initialize()
    
    if res := ma.sound_init_from_file(&audio_engine.engine, "test.wav", {.NO_SPATIALIZATION}, nil, nil, &perc); res != ma.result.SUCCESS {
        fmt.printfln("Failed to load sound: %s", res)
        return
    }
    
    audio_engine->start()
    audio_engine.playhead->setTempo(120)
    // audio_engine.playhead->setPlayheadState(audio.PlayheadState.Playing)
    
    app.signalConnect(audio_engine.playhead.tick_signal, proc(value: audio.TickEvent){
        if value.playhead_state != audio.PlayheadState.Playing {
            return // Only emit tick events when playing
        }
        if value.tick_type == audio.TickType.Beat {
            fmt.println("Beat tick")
        }
        else if value.tick_type == audio.TickType.Bar {
            fmt.println("Bar tick")
        }
    })
   


    // Hardware initialization and main loop
    mpc->initialize()
    mpc.display->router->push("test_page")
    mpc->device->subscribe(onMidiInput)
    ma.sound_start(&perc)
    defer mpc->deInitialize()

    
    mpc.display->run()

    audio_engine->stop()
    audio_engine->uninitialize()
    

}






