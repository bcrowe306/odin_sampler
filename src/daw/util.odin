package daw

import "core:math"
import "core:fmt"


logToNormal_f32 :: proc(value: f32, min: f32, max: f32) -> f32 {
    // Convert a logarithmic value to a normalized 0-1 range
  
    return math.log(value / min, math.E) / math.log(max / min, math.E)
}

normalToLog_f32 :: proc(normalized_value: f32, min: f32, max: f32) -> f32 {
    return min * math.pow_f32(max / min, normalized_value)
}

frequencyToNormal :: proc(frequency: f32, min: f32 = 20.0, max: f32 = 20000.0) -> f32 {
    return logToNormal_f32(frequency, min, max)
}

normalToFrequency :: proc(normalized_value: f32, min: f32 = 20.0, max: f32 = 20000.0) -> f32 {
    return normalToLog_f32(normalized_value, min, max)
}


timeMsToNormal :: proc(time_ms: f32, min_time: f32 = 0.0, max_time: f32 = 10000.0) -> f32 {
    return logToNormal_f32(time_ms, min_time, max_time)
}

normalToTimeMs :: proc(normalized_value: f32, min_time: f32 = 0.0, max_time: f32 = 10000.0) -> f32 {
    return normalToLog_f32(normalized_value, min_time, max_time)
}


timeSecToNormal :: proc(time_sec: f32, min_time: f32 = 0.0, max_time: f32 = 20.0) -> f32 {
    return logToNormal_f32(time_sec, min_time, max_time)
}

normalToTimeSec :: proc(normalized_value: f32, min_time: f32 = 0.0, max_time: f32 = 20.0) -> f32 {
    return normalToLog_f32(normalized_value, min_time, max_time)
}

normalize_f32 :: proc(value: f32, min: f32, max: f32) -> f32 {
    return (value - min) / (max - min)
}

denormalize_f32 :: proc(normalized_value: f32, min: f32, max: f32) -> f32 {
    return normalized_value * (max - min) + min
}

formatFrequency :: proc(frequency: f32) -> string {
    if frequency >= 1000.0 {
        return fmt.tprintf("%.2f kHz", frequency / 1000.0)
    } else {
        return fmt.tprintf("%.2f Hz", frequency)
    }
}

formatDecibels :: proc(db: f32) -> string {
    return fmt.tprintf("%.2f dB", db)
}

formatTime :: proc(time_sec: f32) -> string {
    if time_sec >= 1.0 {
        return fmt.tprintf("%.2f s", time_sec)
    } else {
        return fmt.tprintf("%.2f ms", time_sec * 1000.0)
    }
}


dBToLinear_f32 :: proc(db: f32) -> f32 {
    return math.pow_f32(10.0, db / 20.0)
}

linearToDB_f32 :: proc(linearValue: f32) -> f32 {
    if linearValue <= 0.00001 {
        return -100.0
    }
    return 20.0 * math.log(linearValue, 10.0)
}