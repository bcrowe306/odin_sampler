package audio

import "core:encoding/uuid"
import ma "vendor:miniaudio"
import "core:crypto"

DeviceType :: enum {
    Sampler,
    Synth,
}

Device :: struct {
    id: uuid.Identifier,
    type: DeviceType,
    name: string,
    parameters: []^Parameter,
}

createDevice :: proc(name: string, type: DeviceType = DeviceType.Sampler) -> ^Device {
    new_device := new(Device)
    configureDevice(new_device, name, type)
    return new_device
}

configureDevice :: proc(device: ^Device, name: string, type: DeviceType) {
     context.random_generator = crypto.random_generator()
    device.id = uuid.generate_v4()
    device.name = name
    device.type = type
}