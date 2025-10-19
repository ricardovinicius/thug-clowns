class_name SelectingSpecialTargetState
extends GameState

func enter():
	controller.show_special_range()

func exit():
	controller.clear_highlight()

func process(delta: float):
	pass

func handle_input(event: InputEvent):
	pass

func get_ui_text() -> String:
	return "Select a target for the special ability"
