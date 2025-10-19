class_name SelectingRunTargetState
extends GameState


func enter():
	var character = controller.selected_character

	if character == null:
		push_warning("No character selected in CharacterSelectedState.")
		controller.transition_to(controller.State.IDLE)
		return
	
	print("Selecting run target for character %s." % character.stats.character_name)
	
	controller.show_movement_range(character)

func exit():
	controller.clear_highlight()

func process(delta: float):
	pass

func handle_input(event: InputEvent):
	pass

func get_ui_text() -> String:
	return ""
