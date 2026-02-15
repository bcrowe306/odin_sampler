package hardware_devices

import "../midi"
import "../cairo"
import "core:fmt"
import "core:mem"
import "../control_surface"
import "../daw"

DEVICE_NAME: string = "MPC Studio Black MPC Private"

MPC_SCREEN_WIDTH: i32 : 360
MPC_SCREEN_HEIGHT: i32 : 96
MPC_LINE_STRIDE: i32 : 120
MPC_BIT_STRIDE: i32 : 3
MPC_SCREEN_BYTE_MAP := [3]u8{0x30, 0x0C, 0x03}
MPC_SYSEX_HEADER: [3]u8 = {0x47, 0x7F, 0x3D} // Example header for MPC SysEx messages

MPC_STUDIO_BLACK_MODE :: enum(u8) {
    PRIVATE = 0x61,
    PUBLIC = 0x02,
}

MPC_STUDIO_BLACK_COMMANDS :: enum(u8) {
    SET_MODE = 0x62,
    UPDATE_DISPLAY = 0x04,
    // Add more commands as needed
}



MPC_Studio_Black :: struct {
    using control_surface: control_surface.ControlSurface,
    line_bytes: [MPC_LINE_STRIDE]u8,
    display: ^cairo.Display,

    // Methods
    sendMPCSysexCommand: proc(mpc: ^MPC_Studio_Black, command: MPC_STUDIO_BLACK_COMMANDS, message: []u8),
    setMode: proc(mpc: ^MPC_Studio_Black, mode: MPC_STUDIO_BLACK_MODE),
    sendLine: proc(mpc: ^MPC_Studio_Black, x_pos, y_pos: i32, lineData: []u8),
    isPixelOn: proc(mpc: ^MPC_Studio_Black, a,r,g,b, threshold: u8,) -> bool,


}


createMPCStudioBlack :: proc(daw: ^daw.DAW) -> ^MPC_Studio_Black {

    // TODO: Implement a more robust device detection mechanism that can handle multiple devices and potential naming variations
    // TODO: Maybe provide device as an argument to createMPCStudioBlack for more flexibility
    device := midi.GetDeviceByName(DEVICE_NAME)
    if device == nil {
        fmt.printf("MPC Studio Black device not found.\n")
        return nil
    }
    mpc := new(MPC_Studio_Black)
    control_surface.configureControlSurfaceDefaults(mpc, "MPC Studio Black", device, daw)
    mpc.initialize = initializeMPC
    mpc.deInitialize = deInitializeMPC
    mpc.setMode = setMode
    mpc.sendMPCSysexCommand = sendMPCSysexCommand
    mpc.sendLine = sendLine
    mpc.display = createMPCStudioDisplay()
    mpc.display.widget_render_user_data = mpc
    mpc.display.surface_render_user_data = mpc
    mpc.isPixelOn = isPixelOn

    // Set the display's render function to our custom renderWidget function, which will handle rendering the display content to the MPC
    mpc.display.widget_render = renderWidget
    return mpc
}


setMode :: proc(mpc: ^MPC_Studio_Black, mode: MPC_STUDIO_BLACK_MODE) {
    mpc->sendMPCSysexCommand(MPC_STUDIO_BLACK_COMMANDS.SET_MODE, []u8{u8(mode)})
}


sendMPCSysexCommand :: proc(mpc: ^MPC_Studio_Black, command: MPC_STUDIO_BLACK_COMMANDS, message: []u8) {
    message_length := midi.toMsbLsbArr(u16(len(message)))
    message_type := u8(command)

    sysexMessage := make([]u8, len(MPC_SYSEX_HEADER) + 1 + len(message_length) + len(message)) // Header + Message ID
    copy(sysexMessage, MPC_SYSEX_HEADER[:])
    sysexMessage[len(MPC_SYSEX_HEADER)] = message_type
    copy(sysexMessage[len(MPC_SYSEX_HEADER) + 1:], message_length[:])
    copy(sysexMessage[len(MPC_SYSEX_HEADER) + 1 + len(message_length):], message[:])
    mpc.device->sendSysex(sysexMessage)
}


sendLine :: proc(mpc: ^MPC_Studio_Black, x_pos, y_pos: i32, lineData: []u8) {
    // Construct and send a SysEx message for the line data
    pixel_count := midi.toMsbLsbArr(u16(len(lineData) * 3)) // Each byte represents 3 pixels
    x := midi.toMsbLsbArr(u16(x_pos))
    y := midi.toMsbLsbArr(u16(y_pos))
    payload := make([]u8, len(pixel_count) + len(x) + len(y) + len(lineData))
    copy(payload, pixel_count[:])
    copy(payload[len(pixel_count):], x[:])
    copy(payload[len(pixel_count) + len(x):], y[:])
    copy(payload[len(pixel_count) + len(x) + len(y):], lineData[:])

    mpc->sendMPCSysexCommand(MPC_STUDIO_BLACK_COMMANDS.UPDATE_DISPLAY, payload)
}

renderWidget :: proc(widget_ptr: rawptr) {
    widget := cast(^cairo.Widget)widget_ptr
    mpc := cast(^MPC_Studio_Black)widget.render_user_data
    surface := widget.main_surface
    xPos := i32(widget.bounds.x)
    yPos := i32(widget.bounds.y)
    width := i32(widget.bounds.width)
    height := i32(widget.bounds.height)
    // This function can be used if you want to render the entire display at once instead of line by line
    // It would require buffering the entire display content and sending it in chunks that fit the MPC's requirements
    format := cairo.image_surface_get_format(surface)
    bytes_per_pixel := cairo.format_stride_for_width(format, 1)
    stride := cairo.image_surface_get_stride(surface)
    data := cairo.image_surface_get_data(surface)

    for y :i32 = 0; y < height; y += 1 {
        line_byte_counter := 0
        for x :i32 = 0; x < width; x += 1 {
            
            offset := (y + yPos) * stride + ((x + xPos) * bytes_per_pixel)
           
            if mpc->isPixelOn(data[offset + 3], data[offset + 2], data[offset + 1], data[offset + 0], 250) {
                mpc.line_bytes[x / MPC_BIT_STRIDE] |= MPC_SCREEN_BYTE_MAP[x % MPC_BIT_STRIDE]
            } else {
                mpc.line_bytes[x / MPC_BIT_STRIDE] |= 0x00
            }
            if x % MPC_BIT_STRIDE == 0 && x != 0 {
                line_byte_counter += 1
            }

        }
        mpc->sendLine(xPos, y + yPos, mpc.line_bytes[:line_byte_counter])
        mem.set(&mpc.line_bytes, 0, int(MPC_LINE_STRIDE)) // Clear line bytes for next line
        
    }
}



isPixelOn :: proc(mpc: ^MPC_Studio_Black, a,r,g,b, threshold: u8,) -> bool {
    return r > threshold || g > threshold || b > threshold
}

initializeMPC :: proc(control_surface_ptr: rawptr) {
    // Any initialization code specific to MPC Studio Black can go here
    mpc_studio_black := cast(^MPC_Studio_Black)control_surface_ptr
    mpc_studio_black->setMode(MPC_STUDIO_BLACK_MODE.PRIVATE)
    mpc_studio_black.display->initialize(mpc_studio_black.daw)
    mpc_studio_black.device->startInput()

}

deInitializeMPC :: proc(control_surface_ptr: rawptr) {
    mpc_studio_black := cast(^MPC_Studio_Black)control_surface_ptr
    mpc_studio_black.display->deInitialize()
    mpc_studio_black->setMode(MPC_STUDIO_BLACK_MODE.PUBLIC)
    
}