package app 

import "core:encoding/uuid"
import "core:crypto"

ConnectionID:: uuid.Identifier

SignalConnection :: struct {
    observer: proc(value: any, user_data: rawptr = nil),
    signal: ^Signal,
    user_data: rawptr,
    id: ConnectionID,
}

Signal :: struct{
    connections: [dynamic]^SignalConnection,
    emit: proc(signal: ^Signal, value: any, user_data: rawptr = nil),
    connect: proc(signal: ^Signal, observer: proc(value: any, user_data: rawptr = nil), user_data: rawptr = nil) -> ^SignalConnection,
    disconnect: proc(connection: ^SignalConnection),
    disconnectByID: proc(signal: ^Signal, id: ConnectionID),
    disconnectByObserver: proc(signal: ^Signal, observer: proc(value: any, user_data: rawptr)),
    disconnectAll: proc(signal: ^Signal),
}

createSignal :: proc() -> ^Signal {
    signal := new(Signal)
    signal.emit = signalEmit
    signal.connect = signalConnect
    signal.disconnect = signalDisconnect
    signal.disconnectByID = signalDisconnectByID
    signal.disconnectByObserver = signalDisconnectByObserver
    signal.disconnectAll = signalDisconnectAll
    return signal
}

createSignalConnectionObject :: proc(signal: ^Signal, observer: proc(value: any, user_data: rawptr = nil), user_data: rawptr = nil) -> ^SignalConnection {
    context.random_generator = crypto.random_generator()
    con := new(SignalConnection)
    con.signal = signal
    con.observer = observer
    con.user_data = user_data
    con.id = uuid.generate_v4()
    return con  
}

signalConnect :: proc(signal: ^Signal, observer: proc(value: any, user_data: rawptr = nil), user_data: rawptr = nil) -> ^SignalConnection {
    // Check if the observer is already connected    
    context.random_generator = crypto.random_generator()
    for connection in signal.connections {
        if connection.observer == observer {
            // Observer is already connected, return the existing connection
            return connection
        }
    }
    
    new_connection := createSignalConnectionObject(signal, observer, user_data)
    append(&signal.connections, new_connection)
    return new_connection
}

signalDisconnect :: proc(connection: ^SignalConnection) {
    signal := connection.signal
    for existing_observer, index in signal.connections {
        if existing_observer.id == connection.id {
            // Remove the observer from the list
            ordered_remove(&signal.connections, index)
            return
        }
    }
}

signalDisconnectByID :: proc(signal: ^Signal, id: ConnectionID) {
    for existing_observer, index in signal.connections {
        if existing_observer.id == id {
            // Remove the observer from the list
            ordered_remove(&signal.connections, index)
            return
        }
    }
}

signalDisconnectByObserver :: proc(signal: ^Signal, observer: proc(value: any, user_data: rawptr)) {
    for existing_observer, index in signal.connections {
        if existing_observer.observer == observer {
            // Remove the observer from the list
            ordered_remove(&signal.connections, index)
            return
        }
    }
}


signalDisconnectAll :: proc(signal: ^Signal) {
    clear(&signal.connections)
}

signalEmit :: proc(signal: ^Signal, value: any, user_data: rawptr = nil) {
    for connection in signal.connections {
        if connection.observer != nil {
            connection.observer(value, connection.user_data)
        }
    }
}