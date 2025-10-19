class_name CharacterMovingState
extends GameState


func enter():
	print("Entering CharacterMovingState")

func exit():
	print("Exiting CharacterMovingState")

func process(delta: float):
	pass

func handle_input(event: InputEvent):
	pass

func get_ui_text() -> String:
	return ""
