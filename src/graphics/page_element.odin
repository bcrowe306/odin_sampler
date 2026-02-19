package graphics

import "../app"
import "../cairo"
import clay "../../lib/clay-odin"
import "../daw"


PageElement :: struct {
    using element: Element,
    name: string,
    render_cmd_array: clay.ClayArray(clay.RenderCommand),
    daw: ^daw.DAW,

    // Override this function to create a page layout using elements and clay layout commands
    createLayout: proc(page: rawptr) -> clay.ClayArray(clay.RenderCommand),

    drawPage: proc(page: rawptr, cr: ^cairo.context_t),
    renderPage: proc(page: rawptr, surface: ^cairo.surface_t, render_proc: ElementRenderProc, user_data: rawptr),

    clearPage: proc(page: rawptr, cr: ^cairo.context_t),

    invalidatePage: proc(page_ptr: rawptr),
    // Lifecycle hooks
    beforeLoad: proc(page: rawptr),
    afterLoad: proc(page: rawptr, data: any),
    beforeLeave: proc(page: rawptr),
    afterLeave: proc(page: rawptr),
}

createPageElement :: proc(name: string, layout: proc(page: rawptr) -> clay.ClayArray(clay.RenderCommand) = nil) -> rawptr {
    page := new(PageElement)
    configureElement(page, ElementType.Page)
    page.name = name
    page.createLayout = layout
    page.drawPage = drawPage
    
    // Lifecycle hooks
    page.clearPage = clearPage
    page.invalidatePage = invalidatePage
    return page
}

configurePage :: proc(page: ^PageElement, name: string, layout: proc(page: rawptr) -> clay.ClayArray(clay.RenderCommand) = nil) {
    configureElement(page, ElementType.Page)
    page.name = name
    page.createLayout = layout
    page.drawPage = drawPage
    page.renderPage = renderPage
    
    // Lifecycle hooks
    page.clearPage = clearPage
    page.invalidatePage = invalidatePage
}

clearPage :: proc(page: rawptr, cr: ^cairo.context_t) {
    page := cast(^PageElement)page

    for child_ptr in page.children {
        child := cast(^Element)child_ptr
        if child != nil && child.clear != nil {
            child.clear(child, cr)
        }   
    }
}

invalidatePage :: proc(page_ptr: rawptr) {
    page := cast(^PageElement)page_ptr
    for element_ptr in page.children {
        element := cast(^Element)element_ptr
        if element != nil {
            element.changed = true
        }
    }
}

drawPage :: proc(page: rawptr, cr: ^cairo.context_t) {
    page := cast(^PageElement)page
    if page.createLayout == nil {
        return
    }

    page.render_cmd_array = page.createLayout(page)
    for i in 0..<page.render_cmd_array.length {
        cmd := clay.RenderCommandArray_Get(&page.render_cmd_array, i)

        #partial switch cmd.commandType {
            case clay.RenderCommandType.Rectangle:

            case clay.RenderCommandType.Custom:
                element := cast(^Element)cmd.renderData.custom.customData
                
                #partial switch element.type {
                    case ElementType.Knob:
                        k := cast(^KnobElement)element
                        k.setBounds(k, cairo.getRectFromClayCmd(cmd))
                        if k._draw != nil {
                            k._draw(element, cr)
                        }

                    case ElementType.Slider:
                        // Draw slider based on value

                    case ElementType.Button:
                        // Draw button based on state
                        b := cast(^ButtonElement)element
                        b.setBounds(b, cairo.getRectFromClayCmd(cmd))
                        if b._draw != nil {
                            b._draw(element, cr)
                        }

                    case ElementType.Base:
                        // Draw base element
                    
                    case ElementType.Text:
                        // Draw text element

                    case ElementType.Function:
                        f := cast(^FunctionElement)element
                        f.setBounds(f, cairo.getRectFromClayCmd(cmd))
                        if f._draw != nil {
                            f._draw(element, cr)
                        }

                    case ElementType.Page:
                        // Draw child page element

                    case ElementType.Meter:
                        meter := cast(^MeterElement)element
                        meter.setBounds(meter, cairo.getRectFromClayCmd(cmd))
                        if meter._draw != nil {
                            meter._draw(element, cr)
                        }

                    case ElementType.Pan:
                        // Draw pan based on value

                    case ElementType.Label:
                        l := cast(^LabelElement)element
                        l.setBounds(l, cairo.getRectFromClayCmd(cmd))
                        if l._draw != nil {
                            l._draw(element, cr)
                            
                        }
                }
                
        }

    }
}

// Override this function to create a page layout using elements and clay layout commands
createLayout :: proc() -> clay.ClayArray(clay.RenderCommand) {
    using clay
    BeginLayout()
    return EndLayout()
}

renderPage :: proc(page_ptr: rawptr, surface: ^cairo.surface_t, render_proc: ElementRenderProc, user_data: rawptr) {
    page := cast(^PageElement)page_ptr
    if page.createLayout == nil {
        return
    }

    page.render_cmd_array = page.createLayout(page)
    for i in 0..<page.render_cmd_array.length {
        cmd := clay.RenderCommandArray_Get(&page.render_cmd_array, i)

        #partial switch cmd.commandType {
            case clay.RenderCommandType.Rectangle:

            case clay.RenderCommandType.Custom:
                element := cast(^Element)cmd.renderData.custom.customData
                #partial switch element.type {
                    case ElementType.Knob:
                        e := cast(^KnobElement)element
                        render_proc(element, surface, user_data)
                        e.changed = false

                    case ElementType.Slider:
                        // Draw slider based on value

                    case ElementType.Button:
                        e := cast(^ButtonElement)element
                        render_proc(element, surface, user_data)
                        e.changed = false

                    case ElementType.Base:
                        // Draw base element
                    
                    case ElementType.Text:
                        // Draw text element
                        

                    case ElementType.Function:
                        e := cast(^FunctionElement)element
                        render_proc(element, surface, user_data)

                    case ElementType.Page:
                        // Draw child page element

                    case ElementType.Meter:
                        e := cast(^MeterElement)element
                        render_proc(element, surface, user_data)

                    case ElementType.Pan:
                        // Draw pan based on value

                    case ElementType.Label:
                        e := cast(^LabelElement)element
                        render_proc(element, surface, user_data)
                }
                
        }

    }
}