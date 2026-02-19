package hardware_devices

import "core:fmt"
import daw_pkg "../daw"

PADS_MAX_PAGES :: 4
PADS_PER_PAGE :: 16

PadsControl :: struct {
    using control: daw_pkg.Control,
    pads_map: map[u8]int,
    pads_index: map[int]u8,
    page_index: int,
    setPadColor: proc(control_ptr: rawptr, pad_index: int, color: u8),
}

createPadsControl :: proc() -> ^PadsControl {
    pads := new(PadsControl)
    daw_pkg.configureControl(pads, "PadsControl")
    pads.channel = 9
    pads.page_index = 0
    pads.status = 0x90
    pads.pads_map[37] = 0
    pads.pads_map[36] = 1
    pads.pads_map[42] = 2
    pads.pads_map[82] = 3
    pads.pads_map[40] = 4
    pads.pads_map[38] = 5
    pads.pads_map[46] = 6
    pads.pads_map[44] = 7
    pads.pads_map[48] = 8
    pads.pads_map[47] = 9
    pads.pads_map[45] = 10
    pads.pads_map[43] = 11
    pads.pads_map[49] = 12
    pads.pads_map[55] = 13
    pads.pads_map[51] = 14
    pads.pads_map[53] = 15

    pads.pads_index[0] = 37
    pads.pads_index[1] = 36
    pads.pads_index[2] = 42
    pads.pads_index[3] = 82
    pads.pads_index[4] = 40
    pads.pads_index[5] = 38
    pads.pads_index[6] = 46
    pads.pads_index[7] = 44
    pads.pads_index[8] = 48
    pads.pads_index[9] = 47
    pads.pads_index[10] = 45
    pads.pads_index[11] = 43
    pads.pads_index[12] = 49
    pads.pads_index[13] = 55
    pads.pads_index[14] = 51
    pads.pads_index[15] = 53
    pads.handleInput = handlePadsInput
    pads.setPadColor = setPadColor

    return pads
}

handlePadsInput :: proc(control_ptr: rawptr, msg: ^daw_pkg.ShortMessage) -> bool {
    control := cast(^PadsControl)control_ptr
    if (msg->getMessageType() == control.status && msg->getChannel() == control.channel) {
        if index, ok := control.pads_map[msg.data1]; ok {
            control.daw.tracks->selectTrackByIndex(index + control.page_index * PADS_PER_PAGE)
            return true
        }
    }
    return false
}


setPadColor :: proc(control_ptr: rawptr, pad_index: int, color: u8) {
    control := cast(^PadsControl)control_ptr

    midi_note := control.pads_index[pad_index]
    msg := daw_pkg.MessageFromIntsChannel(daw_pkg.CONTROL_CHANGE, 9, midi_note, color)
    fmt.printfln("msg: %s", msg.toHexString(msg))
    control->sendMidi(msg^)
}
