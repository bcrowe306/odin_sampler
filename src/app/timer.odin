package app

import "core:fmt"

import "core:thread"
import "core:time"

TimerUserData :: struct {
    timer: ^Timer,
    user_data: rawptr,
}

TimerCallback :: proc(user_data: ^TimerUserData)

Timer :: struct {
    // Interval in seconds
    interval: f64,
    frame_duration: time.Duration,
    frame_count: u64,
    current_tick: time.Tick,
    elapsed_duration: time.Duration,
    listeners: [dynamic]TimerCallback,
    removal_queue: [dynamic]TimerCallback,
    addition_queue: [dynamic]TimerCallback,
    threaded: bool,
    running: bool,
    auto_start: bool,
    thread: ^thread.Thread,
    user_data: TimerUserData,
    
    // Methods
    tick: proc(timer: ^Timer),
    start: proc(timer: ^Timer),
    stop: proc(timer: ^Timer),
    loop: proc(timer: ^Timer),
    setInterval: proc(timer: ^Timer, new_interval: f64),
    addListener: proc(timer: ^Timer, listener: TimerCallback),
    removeListener: proc(timer: ^Timer, listener: TimerCallback),
    processQueues: proc(timer: ^Timer),
}

createTimer :: proc(interval: f64, threaded: bool, auto_start: bool = false, callback: TimerCallback = nil, user_data: rawptr = nil) -> ^Timer {
    timer := new(Timer)
    timer.interval = interval
    timer.frame_duration = time.Duration(interval * 1_000_000_000.0) // Convert to nanoseconds
    timer.running = false
    timer.threaded = threaded
    timer.auto_start = auto_start
    timer.tick = timerTick
    timer.start = timerStart
    timer.stop = timerStop
    timer.loop = timerLoop
    timer.processQueues = timerProcessQueues
    timer.addListener = timerAddListener
    timer.removeListener = timerRemoveListener
    timer.setInterval = timerSetInterval
    if callback != nil {
        timer.addListener(timer, callback)
    }
    timer.processQueues(timer) // Ensure any initial callback is added to the listeners
    timer.user_data = TimerUserData{timer, user_data}
    if timer.auto_start {
        timer.start(timer)
    }
    return timer
}

timerSetInterval :: proc(timer: ^Timer, new_interval: f64) {
    timer.interval = new_interval
    fmt.printfln("Timer interval set to %f seconds", new_interval)
    timer.frame_duration = time.Duration(new_interval * 1_000_000_000.0) // Convert to nanoseconds
}

timerAddListener :: proc(timer: ^Timer, listener: TimerCallback) {
    append(&timer.addition_queue, listener)
}

timerRemoveListener :: proc(timer: ^Timer, listener: TimerCallback) {
    append(&timer.removal_queue, listener)
}

timerProcessQueues :: proc(timer: ^Timer) {
    // Process removals
    for listener in timer.removal_queue {
        for i in len(timer.listeners)-1..<0 {
            if timer.listeners[i] == listener {
                ordered_remove(&timer.listeners, i)
                break
            }
        }
    }
    clear(&timer.removal_queue) // Clear the removal queue

    // Process additions
    for listener in timer.addition_queue {
        exists := false
        for existing_listener in timer.listeners {
            if existing_listener == listener {
                exists = true
                break
            }
        }
        if !exists {
            append(&timer.listeners, listener)
        }
    }
    clear(&timer.addition_queue) // Clear the addition queue
}

timerStart :: proc(timer: ^Timer) {
    timer.current_tick = time.tick_now()
    timer.frame_count = 0
    timer.elapsed_duration = 0
    timer.running = true
    if timer.threaded {
        timer.thread = thread.create(timerLoopThreaded)
        timer.thread.data = cast(rawptr)timer
        thread.start(timer.thread)
    }
    else {
        timer->loop()
    }
}

timerStop :: proc(timer: ^Timer) {
    timer.running = false
    if timer.threaded {
        // Join the timer thread
        if timer.thread != nil {
            thread.join(timer.thread)
            free(timer.thread)
        }
    }
}

timerLoopThreaded :: proc(thread: ^thread.Thread) {
    timer := cast(^Timer)thread.data
    for timer.running {
        current_time := time.tick_now()
        timer.elapsed_duration = time.tick_lap_time(&timer.current_tick)
        if timer.elapsed_duration >= timer.frame_duration {
            fmt.printfln("Timer tick at %f seconds (frame %d)", time.duration_seconds(timer.elapsed_duration), timer.frame_count)
            timer->tick()
            timer->processQueues()
        } else {
            time.sleep(timer.frame_duration - timer.elapsed_duration)
        }
    }
}
timerLoop :: proc(timer: ^Timer) {
    for timer.running {
        current_time := time.tick_now()
        timer.elapsed_duration = time.tick_lap_time(&timer.current_tick)
        if timer.elapsed_duration >= timer.frame_duration {
            fmt.printfln("Timer tick at %f seconds (frame %d)", time.duration_seconds(timer.elapsed_duration), timer.frame_count)
            timer->tick()
            timer->processQueues()
        } else {
            time.sleep(timer.frame_duration - timer.elapsed_duration)
        }
    }
}

timerTick :: proc(timer: ^Timer) {
    for listener in timer.listeners {
        if listener != nil {
            listener(&timer.user_data)
        }
    }
    timer.frame_count += 1
}
