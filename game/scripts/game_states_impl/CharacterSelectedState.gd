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

	var attack_button = ui_to_show.get_node("AttackButton")
	var special_ability_button = ui_to_show.get_node("SpecialButton")
	var run_button = ui_to_show.get_node("RunButton")

	special_ability_button.icon = character.stats.special_ability_button_icon

	var icon_display = ui_to_show.get_node("CharacterIcon") as TextureRect

	if icon_display:
		icon_display.texture = character.stats.character_icon
	else:
		push_warning("CharacterIcon node not found in action UI.")

	var char_name_label = ui_to_show.get_node("CharacterName") as Label
	if char_name_label:
		char_name_label.text = character.stats.character_name
	else:
		push_warning("CharacterName node not found in action UI.")

	if character.can_use_standard_action:
		attack_button.disabled = false
		special_ability_button.disabled = false
		run_button.disabled = false
	else:
		attack_button.disabled = true
		special_ability_button.disabled = true
		run_button.disabled = true
	
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
