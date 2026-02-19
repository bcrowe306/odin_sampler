package daw

import "core:encoding/uuid"
import ma "vendor:miniaudio"
import "core:crypto"

InstrumentType :: enum {
    Sampler,
    Synth,
}

Instrument :: struct {
    id: uuid.Identifier,
    type: InstrumentType,
    name: string,
    parameters: []^Parameter,
}

createDevice :: proc(name: string, type: InstrumentType = InstrumentType.Sampler) -> ^Instrument {
    new_device := new(Instrument)
    configureDevice(new_device, name, type)
    return new_device
}

configureDevice :: proc(device: ^Instrument, name: string, type: InstrumentType) {
     context.random_generator = crypto.random_generator()
    device.id = uuid.generate_v4()
    device.name = name
    device.type = type
}