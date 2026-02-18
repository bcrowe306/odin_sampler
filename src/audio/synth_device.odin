package audio

SynthDevice :: struct {
    using device: Device,
    file: string,
}

createSynthDevice :: proc(name: string) -> ^SynthDevice {
    new_device := new(SynthDevice)
    configureDevice(&new_device.device, name, DeviceType.Synth)
    return new_device
}

