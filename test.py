# Mock layer system

# Interface layer. Layer for handling input
# Layer system will be stack based. Each layer can choose to pass input down to the next layer or consume it. This allows for flexible input handling and layering of UI elements.


class InputEvent:
    def __init__(self, type, value):
        self.type = type
        self.value = value

# Individual control
class Control:
    def __init__(self, name):
        self.id = "control_" + name
        self.enabled = True
        self.name = name

    def handle_input(self, event: InputEvent) -> bool:
        # return True if the event was handled, False otherwise
        return False
    
    def process_queues(self):
        # process any pending changes to the control
        pass

# Group of controls
class Component(Control):
    def __init__(self, name) -> None:
        super().__init__(name)
        self.controls: list[Control] = []
        self.removal_queue: list[str] = []

    def add_control(self, control: Control):
        self.controls.append(control)

    def remove_control(self, control: Control):
        self.controls.remove(control)

    def handle_input(self, event: InputEvent) -> bool:
        handled = False
        for control in self.controls:
            if control.enabled:
                if control.handle_input(event):
                    handled = True
        return handled
    
    def process_queues(self):
        # process any pending changes to controls
        for control_id in self.removal_queue:
            for control in self.controls:
                control.process_queues()
        self.removal_queue.clear()

class Layer:
    def __init__(self, name):
        self.name = name
        self.id = "layer_" + name
        self.controls: list[Control] = []

    def add_control(self, control: Control):
        self.controls.append(control)

    def remove_control(self, control: Control):
        self.controls.remove(control)
    
    def handle_input(self, event: InputEvent) -> bool:
        handled = False
        for control in self.controls:
            if control.enabled:
                if control.handle_input(event):
                    handled = True
        return handled
    
    def process_queues(self):
        # process any pending changes to controls or layers
        for control in self.controls:
            control.process_queues()

class App:
    def __init__(self):
        self.layers: list[Layer] = []
    
    def push_layer(self, layer: Layer):
        self.layers.append(layer)

    def pop_layer(self):
        # pop the last layer off the stack
        if len(self.layers) > 0:
            self.layers.pop()

    def handle_input(self, input_event: InputEvent) -> bool:
        # pass the input event down the layer stack until it is handled
        for layer in reversed(self.layers):
            if layer.handle_input(input_event):
                return True
            layer.process_queues()
        return False


class Button(Control):
    def __init__(self, name, value):
        super().__init__(name)
        self.type = "button"
        self.value = value

    def handle_input(self, event: InputEvent) -> bool:
        if event.type == self.type and event.value == self.value:
            print(f"Button {self.name} clicked!")
            return True
        return False


app = App()
main_layer = Layer("main")
top_layer = Layer("top")
button1 = Button("button1", 1)
button2 = Button("button2", 2)
button11 = Button("button11", 1)
main_layer.add_control(button1)
main_layer.add_control(button2)
top_layer.add_control(button11)
app.push_layer(main_layer)
app.push_layer(top_layer)

# Simulate some input events
input_events = [
    InputEvent("button", 1),
    InputEvent("button", 2),
    InputEvent("button", 3),  # This will not be handled
]

for event in input_events:
    if not app.handle_input(event):
        print(f"Event {event.type} with value {event.value} was not handled.")

app.pop_layer()

for event in input_events:
    if not app.handle_input(event):
        print(f"Event {event.type} with value {event.value} was not handled.")