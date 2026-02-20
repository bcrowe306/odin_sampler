package hardware_devices

import "../daw"
import "../graphics"
import "core:fmt"
import clay "../../lib/clay-odin"
import "../cairo"


createMPCStudioBlackContent :: proc(display: ^graphics.Display, daw: ^daw.DAW)  {
    device_page := createDevicePage(display, daw)
    display.router->addPage(device_page)
    display.router->push("device_page", nil)
}

