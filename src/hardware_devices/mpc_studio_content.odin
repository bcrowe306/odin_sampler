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




DevicePage :: struct {
    using page: graphics.PageElement,
    function_buttons: [6] ^graphics.FunctionElement,
    knobs: [4] ^graphics.KnobElement,
    labels: map[string]^graphics.LabelElement,
    buttons : map[string]^graphics.ButtonElement,
    meter: ^graphics.MeterElement,
}



createDevicePage :: proc(display: ^graphics.Display, daw: ^daw.DAW) -> ^DevicePage {
    device_page := new(DevicePage)
    graphics.configurePage(device_page, "device_page", device_page_layout)

    for i in 0..<6 {
        device_page.function_buttons[i] = graphics.createFunctionElement(i, fmt.tprintf("F%d", i + 1), false)
        el := cast(^graphics.Element)device_page.function_buttons[i]
        device_page.addChild(device_page, el)
    }
    device_page.labels["track_name"] = graphics.createLabelElement("Track Name", false)
    device_page.addChild(device_page, cast(^graphics.Element)device_page.labels["track_name"])
    device_page.labels["tempo"] = graphics.createLabelElement("120.00 BPM", false)
    device_page.addChild(device_page, cast(^graphics.Element)device_page.labels["tempo"])
    device_page.labels["song_position"] = graphics.createLabelElement("1.1.1", false)
    device_page.addChild(device_page, cast(^graphics.Element)device_page.labels["song_position"])
    device_page.labels["sequence_number"] = graphics.createLabelElement("Seq: 1", false)
    device_page.addChild(device_page, cast(^graphics.Element)device_page.labels["sequence_number"])
    
    device_page.labels["sequence_length"] = graphics.createLabelElement("Len: 1", false)
    device_page.addChild(device_page, cast(^graphics.Element)device_page.labels["sequence_length"])

    device_page.buttons["play_button"] = graphics.createButtonElement(0, "Play", false)
    device_page.addChild(device_page, cast(^graphics.Element)device_page.buttons["play_button"])


    for i in 0..<4 {
        device_page.knobs[i] = graphics.createKnobElement(fmt.tprintf("Knob %d", i + 1), 0.8)
        el := cast(^graphics.Element)device_page.knobs[i]
        device_page.addChild(device_page, el)
    }

    // Create meter element
    device_page.meter = graphics.createMeterElement(0.0, -60.0, 0.0)
    device_page.addChild(device_page, cast(^graphics.Element)device_page.meter)

    return device_page
}

device_page_layout :: proc(page: rawptr) -> clay.ClayArray(clay.RenderCommand) {
    using clay
    device_page := cast(^DevicePage)page
    BeginLayout()
    if UI()({
        layout = {
            layoutDirection = LayoutDirection.TopToBottom,
            childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Top},
            sizing = {width = SizingGrow({}), height = SizingGrow({})},
            padding= PaddingAll(2),
            childGap=0,
        }
    }) {
        // Header
        if UI()({
            layout = {
                layoutDirection = LayoutDirection.LeftToRight,
                childGap = 8,
                childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Top},
                sizing = {width = SizingGrow({}), height = SizingFixed(20)},
            }
        }){
            // Header content
            selected_track := device_page.daw.tracks.selected_track
            tempo := device_page.daw.transport->getTempo()
            device_page.labels["track_name"]->setText(selected_track.name)
            device_page.labels["tempo"]->setText(fmt.tprintf("%.2f BPM", tempo))
            if UI_AutoId()({
                
                layout = {
                    layoutDirection = LayoutDirection.LeftToRight,
                    childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Top},
                    sizing = {width = SizingGrow({}), height = SizingFixed(14)},
                },
                custom = {customData = device_page.labels["track_name"]}
            }){}
            if UI_AutoId()({
                layout = {
                    layoutDirection = LayoutDirection.LeftToRight,
                    childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Center},
                    sizing = {width = SizingGrow({}), height = SizingFixed(14)},
                },
                custom = {customData = device_page.labels["tempo"]}
            }){}
            if UI_AutoId()({
                layout = {
                    layoutDirection = LayoutDirection.LeftToRight,
                    childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Center},
                    sizing = {width = SizingGrow({}), height = SizingFixed(14)},
                },
                custom = {customData = device_page.labels["song_position"]}
            }){}
            if UI_AutoId()({
                layout = {
                    layoutDirection = LayoutDirection.LeftToRight,
                    childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Center},
                    sizing = {width = SizingGrow({}), height = SizingFixed(14)},
                },
                custom = {customData = device_page.labels["sequence_number"]}
            }){}
            if UI_AutoId()({
                layout = {
                    layoutDirection = LayoutDirection.LeftToRight,
                    childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Center},
                    sizing = {width = SizingGrow({}), height = SizingFixed(14)},
                },
                custom = {customData = device_page.labels["sequence_length"]}
            }){}
            if UI_AutoId()({
                layout = {
                    layoutDirection = LayoutDirection.LeftToRight,
                    childAlignment = {x = LayoutAlignmentX.Left, y = LayoutAlignmentY.Center},
                    sizing = {width = SizingGrow({}), height = SizingFixed(14)},
                },
                custom = {customData = device_page.buttons["play_button"]}
            }){}

        }

        // Body
        if UI()({
            layout = {
                layoutDirection = LayoutDirection.LeftToRight,
                childAlignment = {x = LayoutAlignmentX.Center, y = LayoutAlignmentY.Center},
                childGap = 2,
                sizing = {width = SizingGrow({}), height = SizingGrow({})},
            }
        }) {
            if UI_AutoId()({
                layout = {
                    layoutDirection = LayoutDirection.TopToBottom,
                    childAlignment = {x = LayoutAlignmentX.Center, y = LayoutAlignmentY.Center},
                    sizing = {width = SizingGrow(), height = SizingFixed(55)},
                },
            }){}
            // Body content
            for knob in device_page.knobs {
                if UI_AutoId()({
                    layout = {
                        layoutDirection = LayoutDirection.TopToBottom,
                        
                        childAlignment = {x = LayoutAlignmentX.Center, y = LayoutAlignmentY.Center},
                        sizing = {width = SizingFixed(57), height = SizingFixed(55)},
                    },
                    custom = {customData = knob}
                }){}
            }
            // Meter element
            if UI_AutoId()({
                layout = {
                    layoutDirection = LayoutDirection.TopToBottom,
                    childAlignment = {x = LayoutAlignmentX.Center, y = LayoutAlignmentY.Center},
                    sizing = {width = SizingFixed(57), height = SizingFixed(55)},
                },
                custom = {customData = device_page.meter}
            }){}
            
        }

        // Footer
        if UI()({
            layout = {
                layoutDirection = LayoutDirection.LeftToRight,
                childAlignment = {x = LayoutAlignmentX.Center, y = LayoutAlignmentY.Bottom},
                sizing = {width = SizingGrow({}), height = SizingFixed(12)},
                padding = {left = 2, right = 2, top = 0, bottom = 0},
                childGap = 4,
            },
        }) 
        {
            // Footer content
            
            for btn in device_page.function_buttons {
                if UI_AutoId()({
                    layout = {
                        layoutDirection = LayoutDirection.LeftToRight,
                        sizing = {width = SizingGrow({}), height = SizingFixed(12)},
                        
                    },
                    custom = {customData = btn}
                }){}
            }

        }
    }
    return EndLayout()
}