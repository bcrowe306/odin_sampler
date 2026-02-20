package hardware_devices

import "../cairo"
import "core:fmt"
import "core:mem"
import daw_pkg "../daw"
import "../graphics"


MPC_Studio_Black :: struct {
    using control_surface: daw_pkg.ControlSurface,
    line_bytes: [MPC_LINE_STRIDE]u8,
    display: ^graphics.Display,

    // Methods
    sendMPCSysexCommand: proc(mpc: ^MPC_Studio_Black, command: MPC_STUDIO_BLACK_COMMANDS, message: []u8),
    setMode: proc(mpc: ^MPC_Studio_Black, mode: MPC_STUDIO_BLACK_MODE),
    sendLine: proc(mpc: ^MPC_Studio_Black, x_pos, y_pos: i32, lineData: []u8),
    isPixelOn: proc(mpc: ^MPC_Studio_Black, a,r,g,b, threshold: u8,) -> bool,


}


createMPCStudioBlack :: proc() -> ^MPC_Studio_Black {


    mpc := new(MPC_Studio_Black)
    daw_pkg.configureControlSurfaceDefaults(mpc, "MPC Studio Black")
    mpc.device_name = DEVICE_NAME
    mpc.onInitialize = initializeMPC
    mpc.deInitialize = deInitializeMPC
    mpc.setMode = setMode
    mpc.sendMPCSysexCommand = sendMPCSysexCommand
    mpc.sendLine = sendLine
    mpc.display = createMPCStudioDisplay()
    mpc.display.element_render_user_data = mpc
    mpc.display.surface_render_user_data = mpc
    mpc.isPixelOn = isPixelOn

    // Set the display's render function to our custom renderElement function, which will handle rendering the display content to the MPC
    mpc.display.element_render = renderElement
    createMPCStudioBlackComponents( mpc )
    return mpc
}


setMode :: proc(mpc: ^MPC_Studio_Black, mode: MPC_STUDIO_BLACK_MODE) {
    mpc->sendMPCSysexCommand(MPC_STUDIO_BLACK_COMMANDS.SET_MODE, []u8{u8(mode)})
}


sendMPCSysexCommand :: proc(mpc: ^MPC_Studio_Black, command: MPC_STUDIO_BLACK_COMMANDS, message: []u8) {
    message_length := daw_pkg.toMsbLsbArr(u16(len(message)))
    message_type := u8(command)

    sysexMessage := make([]u8, len(MPC_SYSEX_HEADER) + 1 + len(message_length) + len(message)) // Header + Message ID
    copy(sysexMessage, MPC_SYSEX_HEADER[:])
    sysexMessage[len(MPC_SYSEX_HEADER)] = message_type
    copy(sysexMessage[len(MPC_SYSEX_HEADER) + 1:], message_length[:])
    copy(sysexMessage[len(MPC_SYSEX_HEADER) + 1 + len(message_length):], message[:])
    mpc->sendSysex(sysexMessage)
}


sendLine :: proc(mpc: ^MPC_Studio_Black, x_pos, y_pos: i32, lineData: []u8) {
    // Construct and send a SysEx message for the line data
    pixel_count := daw_pkg.toMsbLsbArr(u16(len(lineData) * 3)) // Each byte represents 3 pixels
    x := daw_pkg.toMsbLsbArr(u16(x_pos))
    y := daw_pkg.toMsbLsbArr(u16(y_pos))
    payload := make([]u8, len(pixel_count) + len(x) + len(y) + len(lineData))
    copy(payload, pixel_count[:])
    copy(payload[len(pixel_count):], x[:])
    copy(payload[len(pixel_count) + len(x):], y[:])
    copy(payload[len(pixel_count) + len(x) + len(y):], lineData[:])

    mpc->sendMPCSysexCommand(MPC_STUDIO_BLACK_COMMANDS.UPDATE_DISPLAY, payload)
}

renderElement :: proc(element_ptr: rawptr, surface: ^cairo.surface_t, render_user_data: rawptr) {
    element := cast(^graphics.Element)element_ptr
    if !element.changed {
        // fmt.printf("Element: %s has not changed, skipping render\n", element.type)
        return
    }
    mpc := cast(^MPC_Studio_Black)render_user_data
    xPos := i32(element.bounds.x) - 1
    yPos := i32(element.bounds.y) - 1
    width := i32(element.bounds.width)
    height := i32(element.bounds.height)
    xPos = clamp(xPos, 0, MPC_SCREEN_WIDTH - 1)
    yPos = clamp(yPos, 0, MPC_SCREEN_HEIGHT - 1)

    // fmt.printf("Bounds: x=%d, y=%d, width=%d, height=%d\n", xPos, yPos, width, height)


    format := cairo.image_surface_get_format(surface)
    bytes_per_pixel := cairo.format_stride_for_width(format, 1)
    stride := cairo.image_surface_get_stride(surface)
    data := cairo.image_surface_get_data(surface)
    y_end := yPos + height
    x_end := xPos + width

    for y :i32 = 0; y + yPos <= y_end; y += 1 {
        line_byte_counter := 0
        final_x_val: i32 = 0
        for x :i32 = 0; x + xPos <= x_end + 1; x += 1 {
            
            offset := (y + yPos ) * stride + ((x + xPos) * bytes_per_pixel)
           
            if mpc->isPixelOn(data[offset + 3], data[offset + 2], data[offset + 1], data[offset + 0], 128) {
                mpc.line_bytes[x / MPC_BIT_STRIDE] |= MPC_SCREEN_BYTE_MAP[x % MPC_BIT_STRIDE]
            } else {
                mpc.line_bytes[x / MPC_BIT_STRIDE] |= 0x00
            }
            if x % MPC_BIT_STRIDE == 0 && x != 0 {
                line_byte_counter += 1
            }
            final_x_val = x
            
        }
        // Handle case where line width is not perfectly divisible by MPC_BIT_STRIDE
        if final_x_val % MPC_BIT_STRIDE > 0 {
            line_byte_counter += 1
        }

        // Send the line data to the MPC via sysex
        mpc->sendLine(xPos, y + yPos, mpc.line_bytes[:line_byte_counter])

        // Debug: Print line byte data before sending
        // debugLineData(mpc.line_bytes[:line_byte_counter], line_byte_counter)

        // Clear line bytes for next line
        mem.set(&mpc.line_bytes, 0, int(MPC_LINE_STRIDE)) // Clear line bytes for next line
        
    }
    element.changed = false
}

debugLineData :: proc(lineData: []u8, length: int) {
    line_byte_string := ""
    for i in 0..<length {
        line_byte_string = fmt.tprint(line_byte_string, "%02X ", lineData[i])
    }
    fmt.printfln("Line Data: %s", line_byte_string)
}

isPixelOn :: proc(mpc: ^MPC_Studio_Black, a,r,g,b, threshold: u8,) -> bool {
    return r > threshold || g > threshold || b > threshold
}

initializeMPC :: proc(control_surface_ptr: rawptr, daw: ^daw_pkg.DAW, device_name: string) {
    // Any initialization code specific to MPC Studio Black can go here
    mpc_studio_black := cast(^MPC_Studio_Black)control_surface_ptr
    mpc_studio_black->setMode(MPC_STUDIO_BLACK_MODE.PRIVATE)


    // This is where the display pages routes, and elements are setup!
    createMPCStudioBlackContent(mpc_studio_black.display, mpc_studio_black.daw)
    mpc_studio_black.display->initialize(mpc_studio_black.daw)

}

deInitializeMPC :: proc(control_surface_ptr: rawptr) {
    mpc_studio_black := cast(^MPC_Studio_Black)control_surface_ptr
    mpc_studio_black.display->deInitialize()
    mpc_studio_black->setMode(MPC_STUDIO_BLACK_MODE.PUBLIC)
    
}