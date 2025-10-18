class_name DeployP2State
extends GameState

func enter():
    controller.spawn_layer_p2.visible = true

func exit():
    controller.spawn_layer_p2.visible = false

func process(delta: float):
    pass

func handle_input(event: InputEvent):
    pass

func get_ui_text() -> String:
    return ""