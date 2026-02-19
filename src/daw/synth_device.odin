package daw

SynthInstrument :: struct {
    using instrument: Instrument,
    file: string,
}

createSynthInstrument :: proc(name: string) -> ^SynthInstrument {
    new_ins := new(SynthInstrument)
    configureDevice(&new_ins.instrument, name, InstrumentType.Synth)
    return new_ins
}

