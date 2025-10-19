class_name CharacterSelectState
extends GameState


func enter():
	var character = controller.selected_character

	if character == null:
		push_warning("No character selected in CharacterSelectedState.")
		controller.transition_to(controller.State.IDLE)
		return

	var ui_to_show = controller.action_ui_p1 if controller.current_player_turn == 1 else controller.action_ui_p2
	ui_to_show.show()
	
	print("Character %s selected." % character.stats.character_name)
	
	if character.can_use_move_action:
		controller.show_movement_range(character)

func exit():
	var ui_to_hide = controller.action_ui_p1 if controller.current_player_turn == 1 else controller.action_ui_p2
	ui_to_hide.hide()
	controller.clear_highlight()

func process(delta: float):
	pass

func handle_input(event: InputEvent):
	pass

func get_ui_text() -> String:
	return ""
