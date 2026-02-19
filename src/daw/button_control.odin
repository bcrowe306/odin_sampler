package daw 

import "core:fmt"

ButtonControl :: struct {
    using control : Control,
    pressed: bool,
    onPress: proc(control: ^ButtonControl),
    onRelease: proc(control: ^ButtonControl),
    onClick: proc(control: ^ButtonControl),
    value: u8,
}

    
isMatchingMessage :: proc(control: ^ButtonControl, msg: ^ShortMessage) -> bool {
    return msg->getMessageType() == control.status && msg->getChannel() == control.channel && msg.data1 == control.identifier
}

defaultOnPress :: proc(control: ^ButtonControl) {
    fmt.printf("Button %s Pressed\n", control.name)
}

defaultOnRelease :: proc(control: ^ButtonControl) {
    fmt.printf("Button %s Released\n", control.name)
}

defaultOnClick :: proc(control: ^ButtonControl) {
    fmt.printf("Button %s Clicked\n", control.name)
}

// Handle button Input
handleButtonInput :: proc(ptr: rawptr, msg: ^ShortMessage) -> bool {

    control := cast(^ButtonControl)ptr
    if isMatchingMessage(control, msg) {


        if msg.data2 != control.value {
            control.value = msg.data2
            control->emit(createEvent(EventType.ValueChange, control.name, msg^))
        }
        if msg.data2 > 0 {
            if !control.pressed {
                control.pressed = true
                if control.onPress != nil {
                    control.onPress(control)
                }
                control->emit(createEvent(EventType.Pressed, control.name, msg^))
            }
        } else {
            if control.pressed {
                control.pressed = false
                
                if control.onRelease != nil {
                    control.onRelease(control)
                }
                control->emit(createEvent(EventType.Released, control.name, msg^))
                if control.onClick != nil {
                    control.onClick(control)
                }
                control->emit(createEvent(EventType.Clicked, control.name, msg^))
            }
        }
        return true

    }
    return false
}

createButtonControl :: proc(name: string, channel: u8, status: u8, identifier: u8, midi_device: ^MidiDevice = nil) -> ^ButtonControl {
    button := new(ButtonControl)
    configureControl(button, name)
    button.channel = channel
    button.status = status
    button.identifier = identifier
    button.pressed = false
    button.value = 0
    button.onPress = defaultOnPress
    button.onRelease = defaultOnRelease
    button.onClick = defaultOnClick
    button.handleInput = handleButtonInput
    return button
}