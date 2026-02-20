class Node:
    def __init__(self, name, sample: int = 0):
        self.name = name
        self.render_quantum: int = 0
        self.outputs: list[Node] = []
        self.inputs: list[Node] = []
        self.sample: int = sample
        self.cache: list[int] = []

    def process(self, render_quantum: int, samples: list[int]) -> list[int]:
        if render_quantum == self.render_quantum:
            return self.cache
        else:
            self.render_quantum = render_quantum
            for i in range(len(samples)):
                samples[i] += self.sample
            # copy list to cache
            self.cache = samples.copy()
            return self.cache

class Graph:
    def __init__(self):
        self.nodes: list[Node] = []
        self.process_order: list[Node] = []

    def add_node(self, node: Node):
        self.nodes.append(node)

    def connect(self, from_node: Node, to_node: Node):
        from_node.outputs.append(to_node)
        to_node.inputs.append(from_node)

    def topological_sort(self):
        visited = set()
        self.process_order = []

        def visit(node: Node):
            if node in visited:
                return
            visited.add(node)
            for output in node.outputs:
                visit(output)
            self.process_order.append(node)

        for node in self.nodes:
            visit(node)

    def process(self):
        temp_buffer: list[int] = [0]
        render_quantum: int = 1
        for i in range(len(self.process_order) - 1, -1, -1):
            node = self.process_order[i]
            for inputs in node.inputs:
                inputs.process(render_quantum, temp_buffer)
            node.process(render_quantum, temp_buffer)
            print(f"Node {node.name} -> {temp_buffer}")

            temp_buffer  = [0]  # reset temp buffer for next node

if __name__ == "__main__":
    graph = Graph()

    node_d = Node("D", 4)
    node_a = Node("A", 1)
    node_b = Node("B", 2)
    node_c = Node("C", 3)

    graph.add_node(node_a)
    graph.add_node(node_b)
    graph.add_node(node_c)
    graph.add_node(node_d)

    graph.connect(node_a, node_b)
    graph.connect(node_a, node_c)
    graph.connect(node_b, node_d)
    graph.connect(node_c, node_d)

    graph.topological_sort()
    graph.process()
