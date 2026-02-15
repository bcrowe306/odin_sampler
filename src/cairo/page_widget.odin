package cairo

import "../daw"
import sdl "vendor:sdl3"

PageUpdateMethod :: enum {
    Always,
    OnChange,
    OnEvent,
}

PageWidget :: struct {
    using widget: Widget,
    name: string,
    widgets: [dynamic]rawptr,
    addWidget: proc(page: rawptr, widget: rawptr),
    removeWidget: proc(page: rawptr, widget: rawptr),
    update_method: PageUpdateMethod,
    clearWidgets: proc(page: rawptr),

    // Lifecycle hooks
    beforeLoad: proc(page: ^PageWidget),
    afterLoad: proc(page: ^PageWidget, data: any),
    beforeLeave: proc(page: ^PageWidget),
    afterLeave: proc(page: ^PageWidget),
}

createPageWidget :: proc(name: string, update_method: PageUpdateMethod = PageUpdateMethod.Always) -> ^PageWidget {
    page := new(PageWidget)
    configureNewWidget(cast(^Widget)page, rectangle_t{0, 0, 0, 0})
    page.name = name
    page.addWidget = pageAddWidget
    page.removeWidget = pageRemoveWidget
    page.draw = pageDrawWidgets
    page.initialize = pageInitializeWidget
    page.clearWidgets = clearWidgets
    page.update_method = update_method
    page.update = pageUpdate
    return page
}

pageAddWidget :: proc(page_ptr: rawptr, widget: rawptr) {
    page := cast(^PageWidget)page_ptr
    append(&page.widgets, widget)
}

pageRemoveWidget :: proc(page_ptr: rawptr, widget: rawptr) {
    page := cast(^PageWidget)page_ptr
    for i in 0..<len(page.widgets) {
        if page.widgets[i] == widget {
            ordered_remove(&page.widgets, i)
            break
        }
    }
}

invalidatePage :: proc(page_ptr: rawptr) {
    page := cast(^PageWidget)page_ptr
    for widget_ptr in page.widgets {
        widget := cast(^Widget)widget_ptr
        if widget != nil {
            widget.changed = true
        }
    }
}

clearWidgets :: proc(page_ptr: rawptr) {
    page := cast(^PageWidget)page_ptr
    for widget_ptr in page.widgets {
        widget := cast(^Widget)widget_ptr
        if widget != nil {
            widget->clear()
            
            if widget.render != nil {
                widget->render()
            }
        }
    }
}

pageUpdate :: proc(page_ptr: rawptr, events: ^sdl.Event = nil) {
    page := cast(^PageWidget)page_ptr
    for widget_ptr in page.widgets {
        widget := cast(^Widget)widget_ptr
        if widget != nil && widget.enabled {
             widget->update(events)
        }
    }
}

pageDrawWidgets :: proc(page_ptr: rawptr) {
    page := cast(^PageWidget)page_ptr

    for widget_ptr in page.widgets {
        switch page.update_method {
            case PageUpdateMethod.Always:
                widget := cast(^Widget)widget_ptr
                if widget != nil {
                    widget->clear()
                    if widget.visible {
                        widget->draw()
                    }
                   
                    if widget.render != nil {
                        widget->render()
                    }
                    widget.changed = false
                }
            case PageUpdateMethod.OnChange:
                widget := cast(^Widget)widget_ptr
                if widget != nil && widget.changed  {
                    widget->clear()
                    if widget.visible {
                        widget->draw()
                    }
                    if widget.render != nil {
                        widget->render()
                    }
                    widget.changed = false
                }
            case PageUpdateMethod.OnEvent:
                // In this mode, widgets are responsible for calling draw when events occur
                break
        }
    }
}

pageInitializeWidget :: proc(widget_ptr: rawptr, surface: ^surface_t, daw: ^daw.DAW, render: proc(widget: rawptr) = nil, render_user_data: rawptr = nil) {
    page := cast(^PageWidget)widget_ptr
    page.daw = daw
    for widget_ptr in page.widgets {
        widget := cast(^Widget)widget_ptr
        if widget != nil {
            if widget.initialize != nil {
                widget.initialize(widget_ptr, surface, daw, render, render_user_data)
            }
        }
    }
}