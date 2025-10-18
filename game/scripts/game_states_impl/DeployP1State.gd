class_name DeployP1State
extends GameState

func enter():
    controller.spawn_layer_p1.visible = true

func exit():
    controller.spawn_layer_p1.visible = false

func process(delta: float):
    pass

func handle_input(event: InputEvent):
    pass

func get_ui_text() -> String:
    return ""