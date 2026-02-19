package app 

// TODO: Add ^Signal to the connection struct so that we can disconnect specific observers from specific signals without needing to pass the signal again

SignalConnection :: struct($T: typeid) {
    observer: proc(value: T, user_data: rawptr = nil),
    user_data: rawptr,
}

Signal :: struct($T: typeid){
    observers: [dynamic]SignalConnection(T),
    emit: proc(signal: ^Signal(T), value: T, user_data: rawptr),
}

createSignal :: proc($T: typeid) -> ^Signal(T) {
    signal := new(Signal(T))
    
    return signal
}

signalConnect :: proc(signal: ^Signal($T), observer: proc(value: T, user_data: rawptr = nil), user_data: rawptr = nil) {
    // Check if the observer is already connected
    
    for existing_observer in signal.observers {
        if existing_observer.observer == observer {
            return // Observer is already connected, do nothing
        }
    }
    append(&signal.observers, SignalConnection(T){ observer = observer, user_data = user_data })
}

signalDisconnect :: proc(signal: ^Signal($T), observer: proc(value: T)) {
    for existing_observer, index in signal.observers {
        if existing_observer.observer == observer {
            // Remove the observer from the list
            ordered_remove(&signal.observers, index)
            return
        }
    }
}

signalEmit :: proc(signal: ^Signal($T), value: T) {
    for connection in signal.observers {
        if connection.observer != nil {
            connection.observer(value, connection.user_data)
        }
    }
}