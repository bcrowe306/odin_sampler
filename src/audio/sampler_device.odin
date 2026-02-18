package audio

SamplerDevice :: struct {
    using device: Device,
    file: string,
}


createSamplerDevice :: proc(name: string) -> ^SamplerDevice {
    new_device := new(SamplerDevice)
    configureDevice(&new_device.device, name, DeviceType.Sampler)
    return new_device
}