package daw

import "core:mem"
import "core:fmt"
import "core:encoding/uuid"
import "core:crypto"
import "core:sync"

EngineContext :: struct {
    sample_rate: f64,
    channels: u32,
    frames_per_buffer: u32,
    render_quantum: u64,
}
AudioNodeID :: uuid.Identifier

AudioNode :: struct {
    id: AudioNodeID,
    name: string,
    render_quantum: u64,
    cache: []f32,
    inputs: [dynamic]rawptr,
    outputs: [dynamic]rawptr,
    prepare: proc(node_ptr: rawptr, ctx: EngineContext),
    process: proc(node_ptr: rawptr, ctx: EngineContext, buffer: []f32, frames: u32),
    onProcess: proc(node_ptr: rawptr, ctx: EngineContext, buffer: []f32, frames: u32),
    addInput: proc(node_ptr: rawptr, input_node_ptr: rawptr),
    addOutput: proc(node_ptr: rawptr, output_node_ptr: rawptr),
    removeInput: proc(node_ptr: rawptr, input_node_ptr: rawptr),
    removeOutput: proc(node_ptr: rawptr, output_node_ptr: rawptr),
    inputQueue: [dynamic]rawptr,
    outputQueue: [dynamic]rawptr,
    inputRemovalQueue: [dynamic]rawptr,
    outputRemovalQueue: [dynamic]rawptr,
    processNodeQueues: proc(node_ptr: rawptr),
}

createAudioNode :: proc() -> ^AudioNode {
    node := new(AudioNode)
    configureNode(node)
    return node
}

configureNode :: proc(node: ^AudioNode) {
    context.random_generator = crypto.random_generator()
    node.id = uuid.generate_v4()
    node.prepare = prepareNode
    node.process = processNode
    node.addInput = nodeAddInput
    node.addOutput = nodeAddOutput
    node.removeInput = nodeRemoveInput
    node.removeOutput = nodeRemoveOutput
    node.processNodeQueues = processNodeQueues
}

nodeAddInput :: proc(node_ptr: rawptr, input_node_ptr: rawptr) {
    node := cast(^AudioNode)node_ptr
    append(&node.inputQueue, input_node_ptr)
}

nodeAddOutput :: proc(node_ptr: rawptr, output_node_ptr: rawptr) {
    node := cast(^AudioNode)node_ptr
    append(&node.outputQueue, output_node_ptr)
}

nodeRemoveInput :: proc(node_ptr: rawptr, input_node_ptr: rawptr) {
    node := cast(^AudioNode)node_ptr
    append(&node.inputRemovalQueue, input_node_ptr)
}

nodeRemoveOutput :: proc(node_ptr: rawptr, output_node_ptr: rawptr) {
    node := cast(^AudioNode)node_ptr
    append(&node.outputRemovalQueue, output_node_ptr)
}

processNodeQueues :: proc(node_ptr: rawptr) {
    // Process Addition queues
    node := cast(^AudioNode)node_ptr
    for input_ptr in node.inputQueue {
        for existing_ptr in node.inputs {
            if existing_ptr == input_ptr {
                continue
            }
        }
        append(&node.inputs, input_ptr)
    } 
    clear(&node.inputQueue)   
    for output_ptr in node.outputQueue {
        for existing_ptr in node.outputs {
            if existing_ptr == output_ptr {
                continue
            }
        }
        append(&node.outputs, output_ptr)
    }
    clear(&node.outputQueue)

    // Process Removal queues
    for input_ptr in node.inputRemovalQueue {
        for existing_ptr, i in node.inputs {
            if existing_ptr == input_ptr {
                ordered_remove(&node.inputs, i)
                break
            }
        }
    }
    clear(&node.inputRemovalQueue)

    for output_ptr in node.outputRemovalQueue {
        for existing_ptr, i in node.outputs {
            if existing_ptr == output_ptr {
                ordered_remove(&node.outputs, i)
                break
            }
        }
    }
    clear(&node.outputRemovalQueue)
    
}

processNode :: proc(node_ptr: rawptr, ctx: EngineContext, buffer: []f32, frames: u32) {
    // Only process if render quantum has changed since last process call, otherwise cached audio will be used
    node := cast(^AudioNode)node_ptr
    if ctx.render_quantum == node.render_quantum {
        copy(buffer[:], node.cache[:]) // Copy input buffer to temp buffer for mixing

    } else {
        if node.onProcess != nil {
            node.onProcess(node_ptr, ctx, buffer, frames)
        }
        // Store rendered buffer in cache
        copy(node.cache[:], buffer[:]) 
    }
    node.render_quantum = ctx.render_quantum
}

prepareNode :: proc(node_ptr: rawptr, ctx: EngineContext) {
    node := cast(^AudioNode)node_ptr
    if u32(len(node.cache)) != ctx.frames_per_buffer * ctx.channels {
        node.cache = make([]f32, ctx.frames_per_buffer * ctx.channels)
    }
}
