package daw

import "core:mem"
import "core:fmt"
import "core:encoding/uuid"
import "core:crypto"
import "core:sync"

/*
Graph structure and processing order:
    Prepare Phase: if engine settings change call prepare on all nodes in graph
    ProcessQueue Phase: For each node in graph, process input and output queues to update connections
    If graph structure has changed, rebuild processing graph and determine new processing order via topological sort. 
        Swap in new processing graph atomically to avoid threading issues with audio callback
    Render Phase: Process nodes in order determined by topological sort of graph, where nodes are processed after all their inputs have been processed

*/

AudioGraph :: struct {
    isDirty: bool, // Set to true whenever graph structure changes (nodes added/removed, connections made/removed) to trigger rebuild of processing graph in audio callback
    nodes: [dynamic]rawptr,
    visited: [dynamic]AudioNodeID,
    endpoint: ^AudioNode, // Special node representing audio output, all nodes that are not directly connected to output will be processed as inputs to this node   
    prepare: proc(graph_ptr: ^AudioGraph, ctx: EngineContext),
    processQueues: proc(graph_ptr: ^AudioGraph),
    processing_graph: [dynamic]rawptr,
    temp_processing_graph: [dynamic]rawptr,
    addNode: proc(graph_ptr: ^AudioGraph, node_ptr: rawptr),
    connect: proc(graph_ptr: ^AudioGraph, output_node_ptr: rawptr, input_node_ptr: rawptr),
    disconnect: proc(graph_ptr: ^AudioGraph, output_node_ptr: rawptr, input_node_ptr: rawptr),
    buildProcessingGraph: proc(graph_ptr: ^AudioGraph),
    process: proc(graph_ptr: ^AudioGraph, ctx: EngineContext, buffer: []f32, frames: u32),
    setVisited: proc(graph_ptr: ^AudioGraph, node_id: AudioNodeID),
    initialize: proc(graph_ptr: ^AudioGraph),
    temp_buffer: []f32,
    input_buffer: []f32,
    zero_buffer: []f32,
    getEndpoint: proc(graph_ptr: ^AudioGraph) -> rawptr,
    p: rawptr
}

createAudioGraph :: proc() -> ^AudioGraph {
    graph := new(AudioGraph)
    graph.isDirty = true
    graph.endpoint = createAudioNode()
    graph.endpoint.name = "Graph Endpoint"
    graph.getEndpoint = getGraphEndpoint
    graph.prepare = prepareGraph
    graph.processQueues = graphProcessQueues
    graph.addNode = graphAddNode
    graph.connect = graphConnect
    graph.disconnect = graphDisconnect
    graph.buildProcessingGraph = buildProcessingGraph
    graph.setVisited = graphSetVisited
    graph.process = graphProcess
    graph.initialize = initializeAudioGraph
    return graph
}

initializeAudioGraph :: proc(graph: ^AudioGraph) {
    graph.p = cast(rawptr)&graph.processing_graph
}

getGraphEndpoint :: proc(graph_ptr: ^AudioGraph) -> rawptr {
    return cast(rawptr)graph_ptr.endpoint
}

graphAddNode :: proc(graph: ^AudioGraph, new_node_ptr: rawptr) {
    new_node := cast(^AudioNode)new_node_ptr
    for node_ptr, index in graph.nodes {
        node := cast(^AudioNode)node_ptr
        if node.id == new_node.id {
            fmt.println("Node with ID ", node.id, " already exists in graph. Skipping add.")
            return
        }
    }
    append(&graph.nodes, cast(rawptr)new_node)
}

graphSetVisited :: proc(graph: ^AudioGraph, node_id: AudioNodeID) {
    for id in graph.visited {
        if id == node_id {
            return
        }
    }
    append(&graph.visited, node_id)
}

graphConnect :: proc(graph: ^AudioGraph, from_ptr: rawptr, to_ptr: rawptr) {
    from_node := cast(^AudioNode)from_ptr
    to_node := cast(^AudioNode)to_ptr
    append(&from_node.outputs, to_ptr)
    append(&to_node.inputs, from_ptr)
    sync.atomic_store(&graph.isDirty, true)
}

graphDisconnect :: proc(graph: ^AudioGraph, from_ptr: rawptr, to_ptr: rawptr) {
    from_node := cast(^AudioNode)from_ptr
    to_node := cast(^AudioNode)to_ptr
    from_node.removeOutput(from_ptr, to_ptr)
    to_node.removeInput(to_ptr, from_ptr)
    sync.atomic_store(&graph.isDirty, true)
}

prepareGraph :: proc(graph: ^AudioGraph, ctx: EngineContext) {
    fmt.printfln("Engine settings changed, preparing graph with new settings: sample_rate=%f, channels=%d, frames_per_buffer=%d", ctx.sample_rate, ctx.channels, ctx.frames_per_buffer)
    if len(graph.temp_buffer) != int(ctx.frames_per_buffer * ctx.channels) {
        graph.temp_buffer = make([]f32, ctx.frames_per_buffer * ctx.channels)
    }
    if len(graph.input_buffer) != int(ctx.frames_per_buffer * ctx.channels) {
        graph.input_buffer = make([]f32, ctx.frames_per_buffer * ctx.channels)
    }
    if len(graph.zero_buffer) != int(ctx.frames_per_buffer * ctx.channels) {
        graph.zero_buffer = make([]f32, ctx.frames_per_buffer * ctx.channels)
    }
    for node_ptr in graph.nodes {
        node := cast(^AudioNode)node_ptr
        node.prepare(node_ptr, ctx)
    }
}
isVisited :: proc(graph: ^AudioGraph, node_id: AudioNodeID) -> bool {
    for id in graph.visited {
        if id == node_id {
            return true
        }
    }
    return false
}
graphProcessQueues :: proc(graph: ^AudioGraph) {

    // Process queues if graph is dirty, otherwise skip to save processing time
    if sync.atomic_load(&graph.isDirty) {
        fmt.println("Processing node queues for graph")
        for node_ptr in graph.nodes {
            node := cast(^AudioNode)node_ptr
            node.processNodeQueues(node_ptr)
        }

    }
}

buildProcessingGraph :: proc(graph: ^AudioGraph) {
    // Perform topological sort of graph to determine processing order
    if !sync.atomic_load(&graph.isDirty){
        return
    }
    fmt.println("Graph structure changed, rebuilding processing graph")
    // Perform topological sort using DFS
    clear(&graph.visited)
    clear(&graph.temp_processing_graph)

    visit :: proc(graph: ^AudioGraph, node: ^AudioNode) {
        graph.setVisited(graph, node.id)
        for output_ptr in node.outputs {
            output_node := cast(^AudioNode)output_ptr
            if !isVisited(graph, output_node.id) {
                visit(graph, output_node)
            }
        }
        append(&graph.temp_processing_graph, cast(rawptr)node)
    }

    for node_ptr in graph.nodes {
        node := cast(^AudioNode)node_ptr
        if !isVisited(graph, node.id) {
            visit(graph, node)
        }
    }
    graph.processing_graph = graph.temp_processing_graph
    sync.atomic_store(&graph.isDirty, false)

}


graphProcess :: proc(graph: ^AudioGraph, ctx: EngineContext, buffer: []f32, frames: u32) {
    // Process node queues
    graph->processQueues()

    // Rebuild processing graph if structure has changed
    graph.buildProcessingGraph(graph)

    // Render graph - process nodes in order determined by topological sort, where nodes are processed after all their inputs have been processed
    
    for i := len(graph.processing_graph) - 1; i >= 0; i -= 1 {
        node := cast(^AudioNode)graph.processing_graph[i]
        clearTempBuffer(graph, ctx)
        clearInputBuffer(graph, ctx)

        // TODO: optimize by only clearing buffers that will be written to by current node or its inputs, rather than clearing for every node
        // TODO: optimize by only processing nodes that are upstream of output node, rather than processing entire graph every time
        // TODO: multi-thread processing of nodes that are not dependent on each other, rather than processing entire graph on single thread
        for input_ptr in node.inputs {
            input_node := cast(^AudioNode)input_ptr
                input_node.process(input_ptr, ctx, graph.input_buffer, ctx.frames_per_buffer)

            // Mix input buffer from each input node into temp buffer for processing by current node
            for j in 0..<ctx.frames_per_buffer * ctx.channels {
                graph.temp_buffer[j] += graph.input_buffer[j]
            }
            clearInputBuffer(graph, ctx) // Clear input buffer for next input node to write into
        }
        
        node.process(cast(rawptr)node, ctx, graph.temp_buffer, ctx.frames_per_buffer)

        // Mix output from current node into temp buffer for each output node to read from
        for j in 0..<ctx.frames_per_buffer * ctx.channels {
            buffer[j] += graph.temp_buffer[j]
        }
    }
}


clearTempBuffer :: proc(graph: ^AudioGraph, ctx: EngineContext) {
    copy(graph.temp_buffer[:], graph.zero_buffer[:])

}

clearInputBuffer :: proc(graph: ^AudioGraph, ctx: EngineContext) {
    copy(graph.input_buffer[:], graph.zero_buffer[:])
}



