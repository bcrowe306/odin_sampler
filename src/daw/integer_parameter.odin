package daw
import "core:fmt"

IntegerParameter :: struct {
    using param: Parameter,
    value: int,
    min: int,
    max: int,
    defult: int,
    step: int,
    step_small: int,
    set: proc(param: ^IntegerParameter, new_value: int),
    get: proc(param: ^IntegerParameter) -> int,
    getValueString: proc(param: ^IntegerParameter) -> string,
    valueStringProc: proc(value: int) -> string,
    changed : proc(param: ^IntegerParameter, new_value: int),
    logarithmic: bool,
}


createIntegerParam :: proc(name: string, default: int, min: int, max: int, step: int = 10, small_step: int = 1, logarithmic: bool = false) -> ^IntegerParameter {
    new_param := new(IntegerParameter)
    configureParameter(&new_param.param, name)
    new_param.type = ParameterType.Integer
    new_param.name = name
    new_param.value = default
    new_param.min = min
    new_param.max = max
    new_param.defult = default
    new_param.step = step
    new_param.step_small = small_step
    new_param.encode = encodeParamInt
    new_param.set = setIntParam
    new_param.get = getIntParam
    new_param.logarithmic = logarithmic
    new_param.getUnit = getIntParamUnit
    new_param.getValueString = getIntParamValueString
    return new_param
}

encodeParamInt :: proc (param_ptr: rawptr, multiplier: f32, small: bool = false) {
    param := cast(^IntegerParameter)param_ptr
    unit_value := normalize_f32(f32(param.value), f32(param.min), f32(param.max))
    if param.logarithmic {
        unit_value = logToNormal_f32(f32(param.value), f32(param.min), f32(param.max))
    }
    fmt.printfln("Unit value before jog: %.4f", unit_value)
    step := param.step
    if small {
        step = param.step_small
    }
    new_unit_value := clamp(unit_value + f32(f32(step) * multiplier), 0.0, 1.0)
    new_value := denormalize_f32(new_unit_value, f32(param.min), f32(param.max))
    if param.logarithmic {
        new_value = normalToLog_f32(new_unit_value, f32(param.min), f32(param.max))
    }
    fmt.printfln("New unit value after jog: %.4f", new_unit_value)
    param.set(param, int(new_value))
}

setIntParam :: proc(param: ^IntegerParameter, new_value: int) {
    clamped_value := clamp(new_value, param.min, param.max)
    param.value = clamped_value
    if param.changed != nil {
        param.changed(param, clamped_value)
    }
}
getIntParam :: proc(param: ^IntegerParameter) -> int {
    return param.value
}

getIntParamUnit :: proc(param: rawptr) -> f32 {
    param := cast(^IntegerParameter)param
    if param.logarithmic {
        return logToNormal_f32(f32(param.value), f32(param.min), f32(param.max))
    }
    else {
        return normalize_f32(f32(param.value), f32(param.min), f32(param.max))
    }
}

getIntParamValueString :: proc(param: ^IntegerParameter) -> string {
    if param.valueStringProc != nil {
        return param.valueStringProc(param.value)
    } else {
        if param.formatString != "" {
            return fmt.tprintf(param.formatString, param.value)
        }
        return fmt.tprintf("%d", param.value)
    }
}

