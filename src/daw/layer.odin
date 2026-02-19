package daw

import "core:encoding/uuid"
import "core:crypto"

Layer :: struct {
    id: uuid.Identifier,
    name: string,
    components: [dynamic]rawptr,
    addQueue: [dynamic]rawptr,
    removalQueue: [dynamic]uuid.Identifier,
    addComponent: proc(layer: ^Layer, component: rawptr),
    removeComponent: proc(layer: ^Layer, component: rawptr),
    handleInput: proc(layer_ptr: ^Layer, msg: ^ShortMessage) -> bool,
    processQueues: proc(layer: ^Layer),
}

createLayer :: proc(name: string) -> ^Layer {
    context.random_generator = crypto.random_generator()
    layer := new(Layer)
    layer.id = uuid.generate_v4()
    layer.name = name
    layer.handleInput = defaultLayerInputHandler
    layer.addComponent = addComponent
    layer.removeComponent = removeComponent
    layer.processQueues = processLayerQueues
    return layer
}


defaultLayerInputHandler :: proc(layer: ^Layer, msg: ^ShortMessage) -> bool {
    handled := false
    for component_ptr in layer.components {
        component := cast(^Component)component_ptr
        if component.enabled {
            if component.handleInput(component, msg) {
                handled = true
            }
        }
    }
    return handled
}

addComponent :: proc(layer: ^Layer, new_component_type: $T) {
    new_ptr := cast(rawptr)new_component_type
    append(&layer.addQueue, new_ptr)
}

removeComponent :: proc(layer: ^Layer, component_to_remove_type: $T) {
    append(&layer.removalQueue, (cast(^Component)component_to_remove_type).id)
}

processLayerQueues :: proc(layer: ^Layer) {
    // Process additions
    for new_component_ptr in layer.addQueue {
        append(&layer.components, new_component_ptr)
    }
    clear(&layer.addQueue)
    
    // Process removals
    for id in layer.removalQueue {
        for i in 0..<len(layer.components) {
            component := cast(^Component)layer.components[i]
            if component.id == id {
                ordered_remove(&layer.components, i)
                break
            }
        }
    }
    clear(&layer.removalQueue)
}