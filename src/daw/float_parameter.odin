package daw

import "core:fmt"

FloatParameter :: struct {
    using param: Parameter,
    value: f32,
    min: f32,
    max: f32,
    defult: f32,
    step: f32,
    step_small: f32,
    set: proc(param: ^FloatParameter, new_value: f32),
    get: proc(param: ^FloatParameter) -> f32,
    getValueString: proc(param: ^FloatParameter) -> string,
    valueStringProc: proc(value: f32) -> string,
    changed : proc(param: ^FloatParameter, new_value: f32),
    logarithmic: bool,
}

createFParam :: proc(name: string, default: f32, min: f32, max: f32, step: f32 = 0.01, small_step: f32 = 0.001, logarithmic: bool = false) -> ^FloatParameter {
    new_param := new(FloatParameter)
    configureParameter(&new_param.param, name)
    new_param.type = ParameterType.Float
    new_param.name = name
    new_param.value = default
    new_param.min = min
    new_param.max = max
    new_param.defult = default
    new_param.step = step
    new_param.step_small = small_step
    new_param.encode = encodeParamF
    new_param.set = setFParam
    new_param.get = getFParam
    new_param.logarithmic = logarithmic
    new_param.getUnit = getFParamUnit
    new_param.getValueString = getFParamValueString
    return new_param
}

encodeParamF :: proc (param_ptr: rawptr, multiplier: f32, small: bool = false) {
    param := cast(^FloatParameter)param_ptr
    unit_value := normalize_f32(param.value, param.min, param.max)
    if param.logarithmic {
        unit_value = logToNormal_f32(param.value, param.min, param.max)
    }
    fmt.printfln("Unit value before jog: %.4f", unit_value)
    step := param.step
    if small {
        step = param.step_small
    }
    new_unit_value := clamp(unit_value + step * multiplier, 0.0, 1.0)
    new_value := denormalize_f32(new_unit_value, param.min, param.max)
    if param.logarithmic {
        new_value = normalToLog_f32(new_unit_value, param.min, param.max)
    }
    fmt.printfln("New unit value after jog: %.4f", new_unit_value)
    param.set(param, new_value)
}

setFParam :: proc(param: ^FloatParameter, new_value: f32) {
    clamped_value := clamp(new_value, param.min, param.max)
    param.value = clamped_value
    if param.changed != nil {
        param.changed(param, clamped_value)
    }
}

getFParam :: proc(param: ^FloatParameter) -> f32 {
    return param.value
}

getFParamUnit :: proc(param: rawptr) -> f32 {
    param := cast(^FloatParameter)param
    if param.logarithmic {
        return logToNormal_f32(param.value, param.min, param.max)
    }
    else {
        return normalize_f32(param.value, param.min, param.max)
    }
}

getFParamValueString :: proc(param: ^FloatParameter) -> string {
    if param.valueStringProc != nil {
        return param.valueStringProc(param.value)
    } else {
        if param.formatString != "" {
            return fmt.tprintf(param.formatString, param.value)
        }
        return fmt.tprintf("%.2f", param.value)
    }
}


createDecibelParam :: proc(name: string, default: f32 = 0.0, min: f32 = -60.0, max: f32 = 12.0, step: f32 = 0.1, small_step: f32 = 0.01) -> ^FloatParameter {
    new_param := createFParam(name, default, min, max, step, small_step, true)
    configureParameter(&new_param.param, name)
    new_param.type = ParameterType.Decibel
    new_param.name = name
    new_param.value = default
    new_param.min = min
    new_param.max = max
    new_param.defult = default
    new_param.step = step
    new_param.step_small = small_step
    new_param.encode = encodeParamF
    new_param.set = setFParam
    new_param.get = getFParam
    new_param.getUnit = getFParamUnit
    new_param.getValueString = getFParamValueString
    new_param.valueStringProc = formatDecibels
    new_param.encode = proc(param_ptr: rawptr, multiplier: f32, small: bool = false) {
        param := cast(^FloatParameter)param_ptr
        unit_value := dBToLinear_f32(param.value)
        fmt.printfln("Unit value before jog: %.4f", unit_value)
        step := param.step
        if small {
            step = param.step_small
        }
        new_unit_value := clamp(unit_value + step * multiplier, 0.0, 1.0)
        new_value := linearToDB_f32(new_unit_value)
        fmt.printfln("New unit value after jog: %.4f", new_unit_value)
        param.set(param, new_value)
    }
    return new_param
}


createFrequencyParam :: proc(name: string, default: f32 = 440, min: f32 = 20.0, max: f32 = 20000.0, step: f32 = 0.01, small_step: f32 = 0.001) -> ^FloatParameter {
    new_param := createFParam(name, default, min, max, step, small_step, true)
    configureParameter(&new_param.param, name)
    new_param.type = ParameterType.Frequency
    new_param.name = name
    new_param.value = default
    new_param.min = min
    new_param.max = max
    new_param.defult = default
    new_param.step = step
    new_param.step_small = small_step
    new_param.encode = encodeParamF
    new_param.set = setFParam
    new_param.get = getFParam
    new_param.getUnit = getFParamUnit
    new_param.getValueString = getFParamValueString
    new_param.valueStringProc = formatFrequency
    new_param.logarithmic = true
    return new_param
}

createTimeParam :: proc(name: string, default: f32 = .01, min: f32 = 0.0, max: f32 = 10.0, step: f32 = 0.01, small_step: f32 = 0.001) -> ^FloatParameter {
    new_param := createFParam(name, default, min, max, step, small_step, true)
    configureParameter(&new_param.param, name)
    new_param.type = ParameterType.Time
    new_param.name = name
    new_param.value = default
    new_param.min = min
    new_param.max = max
    new_param.defult = default
    new_param.step = step
    new_param.step_small = small_step
    new_param.set = setFParam
    new_param.get = getFParam
    new_param.getUnit = getFParamUnit
    new_param.getValueString = getFParamValueString
    new_param.valueStringProc = formatTime
    new_param.logarithmic = true
    new_param.encode = encodeParamF
    return new_param
}
