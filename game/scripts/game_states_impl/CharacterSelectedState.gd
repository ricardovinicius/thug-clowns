class_name CharacterSelectState
extends GameState



func enter():
	var character = controller.selected_character

	if char == null:
		push_warning("No character selected in CharacterSelectedState.")
		controller.transition_to(controller.State.IDLE)
		return

	controller.action_ui.visible = true
	
	print("Character %s selected." % character.stats.character_name)
	
	if character.can_use_move_action:
		controller.show_movement_range(character)

func exit():
	controller.action_ui.visible = false
	controller.clear_movement_range()

func process(delta: float):
	pass

func handle_input(event: InputEvent):
	pass

func get_ui_text() -> String:
	return ""
