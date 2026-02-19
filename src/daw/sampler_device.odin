package daw

SamplerInstrument :: struct {
    using instrument: Instrument,
    file: string,
}


createSamplerDevice :: proc(name: string) -> ^SamplerInstrument {
    new_device := new(SamplerInstrument)
    configureDevice(&new_device.instrument, name, InstrumentType.Sampler)
    return new_device
}