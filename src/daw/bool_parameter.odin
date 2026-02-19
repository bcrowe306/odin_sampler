package daw

import "core:fmt"

BoolParameter :: struct {
    using param: Parameter,
    value: bool,
    defult: bool,
    set: proc(param: ^BoolParameter, new_value: bool),
    get: proc(param: ^BoolParameter) -> bool,
    getValueString: proc(param: ^BoolParameter) -> string,
    valueStringProc: proc(value: bool) -> string,
    changed : proc(param: ^BoolParameter, new_value: bool),
}

createBoolParam :: proc(name: string, default: bool) -> ^BoolParameter {
    new_param := new(BoolParameter)
    new_param.name = name
    new_param.type = ParameterType.Boolean
    new_param.value = default
    new_param.defult = default
    new_param.encode = encodeParamBool
    new_param.set = setBoolParam
    new_param.get = getBoolParam
    new_param.getUnit = getBoolParamUnit
    new_param.getValueString = getBoolParamValueString
    return new_param
}

encodeParamBool :: proc (param_ptr: rawptr, multiplier: f32, small: bool = false) {
    param := cast(^BoolParameter)param_ptr
    if multiplier > 0 {
        param.set(param, true)
    } else if multiplier < 0 {
        param.set(param, false)
    }
}

setBoolParam :: proc(param: ^BoolParameter, new_value: bool) {
    param.value = new_value
    if param.changed != nil {
        param.changed(param, new_value)
    }
}
getBoolParam :: proc(param: ^BoolParameter) -> bool {
    return param.value
}

getBoolParamUnit :: proc(param: rawptr) -> f32 {
    param := cast(^BoolParameter)param
    if param.value {
        return 1.0
    } else {
        return 0.0
    }
}

getBoolParamValueString :: proc(param: ^BoolParameter) -> string {
    if param.valueStringProc != nil {
        return param.valueStringProc(param.value)
    } else {
        if param.formatString != "" {
            return fmt.tprintf(param.formatString, param.value)
        }
        return fmt.tprintf("%d", param.value)
    }
}

