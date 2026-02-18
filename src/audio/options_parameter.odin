package audio 

import "core:c"
import "core:fmt"

OptionsParameter :: struct {
    using param: Parameter,
    value: int,
    defult: int,
    options: []string,
    encode: proc(param: ^OptionsParameter, multiplier: int, small: bool = false),
    encode_count: int,
    encode_threshold: int,
    set: proc(param: ^OptionsParameter, new_value: int),
    get: proc(param: ^OptionsParameter) -> int,
    getUnit: proc(param: ^OptionsParameter) -> f32,
    getValueString: proc(param: ^OptionsParameter) -> string,
    valueStringProc: proc(value: int) -> string,
    changed : proc(param: ^OptionsParameter, new_value: int),
}

createOptionsParam :: proc(name: string, options: []string, default: int = 0) -> ^OptionsParameter {
    new_param := new(OptionsParameter)
    configureParameter(&new_param.param, name)
    new_param.name = name
    new_param.type = ParameterType.Options
    new_param.value = default
    new_param.defult = default
    new_param.encode = encodeOptionsParam
    new_param.encode_threshold = 5
    new_param.options = options
    new_param.set = setOptionsParam
    new_param.get = getOptionsParam
    new_param.getUnit = getOptionsParamUnit
    new_param.getValueString = getOptionsParamValueString
    return new_param
}

encodeOptionsParam :: proc (param: ^OptionsParameter, multiplier: int, small: bool = false) {
    param.encode_count += 1
    if param.encode_count >= param.encode_threshold {
        param.encode_count = 0
        options_count := len(param.options)
        if options_count == 0 {
            return
        }
        if multiplier > 0 {
            param.set(param, (param.value + 1) % options_count)
        } else if multiplier < 0 {
            param.set(param, (param.value - 1 + options_count) % options_count)
        }
    }
    
}

setOptionsParam :: proc(param: ^OptionsParameter, new_value: int) {
    param.value = clamp(new_value, 0, len(param.options) - 1)
    if param.changed != nil {
        param.changed(param, param.value)
    }
}

getOptionsParam :: proc(param: ^OptionsParameter) -> int {
    return param.value
}

getOptionsParamUnit :: proc(param: ^OptionsParameter) -> f32 {
    options_count := len(param.options)
    if options_count == 0 {
        return 0.0
    }
    return f32(param.value) / f32(options_count - 1)
}

getOptionsParamValueString :: proc(param: ^OptionsParameter) -> string {
    if param.valueStringProc != nil {
        return param.valueStringProc(param.value)
    } else {
        if param.formatString != "" {
            return fmt.tprintf(param.formatString, param.value)
        }
        return fmt.tprintf("%s", param.options[param.value])
    }
}

