class_name SelectingAttackTargetState
extends GameState

func enter():
    controller.show_attack_range()

func exit():
    controller.clear_highlight()

func process(delta: float):
    pass

func handle_input(event: InputEvent):
    pass

func get_ui_text() -> String:
    return ""