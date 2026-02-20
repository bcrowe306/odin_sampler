package app

import "core:time"
import "core:math/ease"

RampFloat :: struct {
    target: f32,
    start: f32,
    current: f32,
    current_tick: time.Tick,
    elapsed_duration: time.Duration,
    duration: time.Duration,
    ease: ease.Ease,
    active: proc (ramp: ^RampFloat) -> bool,
    process : proc(ramp: ^RampFloat) -> f32,
    activate: proc(ramp: ^RampFloat, start: f32, target: f32),
    setDuration: proc(ramp: ^RampFloat, ramp_time_milliseconds: u32),
    onUpdated: ^Signal,
}

createRamp :: proc(ramp_time_milliseconds: u32 = 10, ease_type: ease.Ease = ease.Ease.Linear) -> RampFloat {
    return RampFloat{
        setDuration = rampSetDuration,
        duration = time.Duration(ramp_time_milliseconds) * time.Millisecond,
        ease = ease_type,
        process = rampProcess,
        activate = rampActivate,
        active = rampActive,
        onUpdated = createSignal(),
    }
}

rampActive :: proc (ramp: ^RampFloat) -> bool {
    using ramp
    if start < target {
        return current < target
    } else {
        return current > target
    }
}

rampProcess :: proc (ramp: ^RampFloat) -> f32 {
    if ramp.active(ramp) {
        
        ramp.elapsed_duration = ramp.elapsed_duration + time.tick_lap_time(&ramp.current_tick)
        
        progress := clamp(0.0, 1.0, ease.ease(ramp.ease, f32(ramp.elapsed_duration) / f32(ramp.duration)))
        ramp.current = ramp.start + (ramp.target - ramp.start) * progress
        signalEmit(ramp.onUpdated, auto_cast &ramp.current)
        ramp.current_tick = time.tick_now()
    } 
    
    return ramp.current
}

rampActivate :: proc(ramp: ^RampFloat, start: f32, target: f32) {
    ramp.start = start
    ramp.current = start
    ramp.target = target
    ramp.current_tick = time.tick_now()
    ramp.elapsed_duration = 0
}

rampSetDuration :: proc(ramp: ^RampFloat, ramp_time_milliseconds: u32) {
    ramp.duration = time.Duration(ramp_time_milliseconds) * time.Millisecond
}

RampInt :: struct {
    target: i32,
    start: i32,
    current: i32,
    current_tick: time.Tick,
    elapsed_duration: time.Duration,
    duration: time.Duration,
    ease: ease.Ease,
    active: proc (ramp: ^RampInt) -> bool,
    process : proc(ramp: ^RampInt) -> i32,
    activate: proc(ramp: ^RampInt, start: i32, target: i32),
    setDuration: proc(ramp: ^RampInt, ramp_time_milliseconds: u32),
}

createRampInt :: proc(ramp_time_milliseconds: u32 = 10, ease_type: ease.Ease = ease.Ease.Linear) -> RampInt {
    return RampInt{
        setDuration = rampSetDurationInt,
        duration = time.Duration(ramp_time_milliseconds) * time.Millisecond,
        ease = ease_type,
        process = rampProcessInt,
        activate = rampActivateInt,
        active = rampActiveInt,
    }
}

rampActiveInt :: proc (ramp: ^RampInt) -> bool {
    using ramp
    if start < target {
        return current < target
    } else {
        return current > target
    }
}


rampProcessInt :: proc (ramp: ^RampInt) -> i32 {
    if ramp.active(ramp) {
        
        ramp.elapsed_duration = ramp.elapsed_duration + time.tick_lap_time(&ramp.current_tick)
        
        progress := clamp(0.0, 1.0, ease.ease(ramp.ease, f32(ramp.elapsed_duration) / f32(ramp.duration)))
        ramp.current = ramp.start + i32(f32(ramp.target - ramp.start) * progress)

        ramp.current_tick = time.tick_now()
    } 
    
    return ramp.current
}

rampActivateInt :: proc(ramp: ^RampInt, start: i32, target: i32) {
    ramp.start = start
    ramp.current = start
    ramp.target = target
    ramp.current_tick = time.tick_now()
    ramp.elapsed_duration = 0
}


rampSetDurationInt :: proc(ramp: ^RampInt, ramp_time_milliseconds: u32) {
    ramp.duration = time.Duration(ramp_time_milliseconds) * time.Millisecond
}

