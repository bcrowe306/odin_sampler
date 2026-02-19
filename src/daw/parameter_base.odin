package daw

import "core:encoding/uuid"
import "core:crypto"
ParameterType :: enum {
    Integer,
    Float,
    Boolean,
    Options,
    Decibel,
    Frequency,
    Time,
}


Parameter :: struct {
    name: string,
    id: uuid.Identifier,
    type: ParameterType,
    formatString: string,
    process: proc(param: rawptr, frame_count: u32),
    encode: proc(param: rawptr, multiplier: f32, small: bool),
    inc: proc(param: rawptr, multiplier: f32),
    dec: proc(param: rawptr, multiplier: f32),
    getUnit: proc(param: rawptr) -> f32,
}

configureParameter :: proc(param: ^Parameter, name: string) {
    context.random_generator = crypto.random_generator()
    param.id = uuid.generate_v4()
    param.name = name
    param.process = parameterProcess
    param.encode = parameterEncode
    param.inc = parameterInc
    param.dec = parameterDec
    param.getUnit = parameterGetUnit
}

parameterProcess :: proc(param: rawptr, frame_count: u32) {
    // This is a default no-op implementation. Specific parameter types can override this with their own processing logic if needed.
}

parameterEncode :: proc(param: rawptr, multiplier: f32, small: bool) {
    // This is a default no-op implementation. Specific parameter types should override this with their own encoding logic.
}

parameterInc :: proc(param: rawptr, multiplier: f32) {
    // This is a default no-op implementation. Specific parameter types should override this with their own increment logic.
}

parameterDec :: proc(param: rawptr, multiplier: f32) {
    // This is a default no-op implementation. Specific parameter types should override this with their own decrement logic.
}

parameterGetUnit :: proc(param: rawptr) -> f32 {
    // This is a default no-op implementation. Specific parameter types should override this with their own logic to return a normalized unit value between 0.0 and 1.0.
    return 0.0
}

