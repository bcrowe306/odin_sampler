package cairo



WidgetManager :: struct {
    widgets: [dynamic]rawptr,
    addWidget: proc(manager: ^WidgetManager, widget: rawptr),
    removeWidget: proc(manager: ^WidgetManager, widget: rawptr),
    drawWidgets: proc(manager: ^WidgetManager),
    cr: ^context_t,
    displays: [dynamic]displayRenderFunc,
    dataPtrs: [dynamic]rawptr,
    addDisplay: proc(manager: ^WidgetManager, display: displayRenderFunc, dataPtr: rawptr),
    removeDisplay: proc(manager: ^WidgetManager, display: displayRenderFunc),
}

addDisplay :: proc(manager: ^WidgetManager, display: displayRenderFunc, dataPtr: rawptr) {
    
    append(&manager.displays, display)
    append(&manager.dataPtrs, dataPtr)
}

removeDisplay :: proc(manager: ^WidgetManager, display: displayRenderFunc) {
    for i in 0..<len(manager.displays) {
        if manager.displays[i] == display {
            ordered_remove(&manager.displays, i)
            ordered_remove(&manager.dataPtrs, i)
            break
        }
    }
}

createWidgetManager :: proc(cr: ^context_t) -> ^WidgetManager {
    manager := new(WidgetManager)
    manager.addWidget = wmAddWidget
    manager.removeWidget = wmRemoveWidget
    manager.drawWidgets = wmDrawWidgets
    manager.addDisplay = addDisplay
    manager.removeDisplay = removeDisplay
    manager.cr = cr
    return manager
}

wmAddWidget :: proc(manager: ^WidgetManager, widget: rawptr) {
    append(&manager.widgets, widget)
}

wmRemoveWidget :: proc(manager: ^WidgetManager, widget: rawptr) {
    for i in 0..<len(manager.widgets) {
        if manager.widgets[i] == widget {
            ordered_remove(&manager.widgets, i)
            break
        }
    }
}

wmDrawWidgets :: proc(manager: ^WidgetManager) {

    for widget_ptr in manager.widgets {
        widget := cast(^Widget)widget_ptr
        if widget.visible && widget.changed {
            set_source_rgba(widget.cr, 0.0, 0.0, 0.0, 1.0)
            paint(widget.cr)
            widget.draw(widget_ptr)
            for i in 0..<len(manager.displays) {
                display := manager.displays[i]
                dataPtr := manager.dataPtrs[i]
                display(widget.main_surface, i32(widget.bounds.x), i32(widget.bounds.y), i32(widget.bounds.width), i32(widget.bounds.height), dataPtr)
            }
            
        }
        widget.changed = false

    }
}
