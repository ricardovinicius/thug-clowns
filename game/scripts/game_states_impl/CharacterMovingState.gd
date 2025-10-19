class_name CharacterMovingState
extends GameState


func enter():
	print("Entering CharacterMovingState")
	var character = controller.selected_character
	
	if character and character.sprite:
		character.sprite.play("walking")

func exit():
	print("Exiting CharacterMovingState")
	var character = controller.selected_character

	if character and character.sprite:
		character.sprite.stop()
		character.sprite.play("idle")
		


func process(delta: float):
	pass

func handle_input(event: InputEvent):
	pass

func get_ui_text() -> String:
	return ""
