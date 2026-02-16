package app 


Signal :: struct($T: typeid){
    observers: [dynamic]proc(value: T),
    connect: proc(signal: ^Signal(T), observer: proc(value: T)),
    disconnect: proc(signal: ^Signal(T), observer: proc(value: T)),
    emit: proc(signal: ^Signal(T), value: T),
}

createSignal :: proc($T: typeid) -> ^Signal(T) {
    signal := new(Signal(T))
    
    return signal
}

signalConnect :: proc(signal: ^Signal($T), observer: proc(value: T)) {
    // Check if the observer is already connected
    for existing_observer in signal.observers {
        if existing_observer == observer {
            return // Observer is already connected, do nothing
        }
    }
    append(&signal.observers, observer)
}

signalDisconnect :: proc(signal: ^Signal($T), observer: proc(value: T)) {
    for existing_observer, index in signal.observers {
        if existing_observer == observer {
            // Remove the observer from the list
            ordered_remove(&signal.observers, index)
            return
        }
    }
}

signalEmit :: proc(signal: ^Signal($T), value: T) {
    for observer in signal.observers {
        if observer != nil {
            observer(value)
        }
    }
}