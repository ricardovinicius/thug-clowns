extends Node2D

@export var tilemap: TileMapLayer
@export var spawn_layer_p1: TileMapLayer
@export var spawn_layer_p2: TileMapLayer
@export var highlight_layer: TileMapLayer
@export var selector: Sprite2D
@export var turn_label: Label
@export var round_label: Label

@export var tank_scene: PackedScene
@export var ranged_scene: PackedScene
@export var mid_scene: PackedScene

@onready var action_ui_p1 = $CanvasLayer/ActionUI_P1
@onready var action_ui_p2 = $CanvasLayer/ActionUI_P2

const HIGHLIGHT_SOURCE_ID = 1
const HIGHLIGHT_ATLAS_COORDS = Vector2i(0, 0)

const ATTACK_HIGHLIGHT_SOURCE_ID = 0 # Mesmo TileSet
const ATTACK_HIGHLIGHT_ATLAS_COORDS = Vector2i(0, 0)

var p1_troops_to_deploy: Array[PackedScene] = []
var p2_troops_to_deploy: Array[PackedScene] = []
	

var occupied_tiles = {}

var hovered_grid_pos: Vector2i

const SELECTABLE_LAYER = 2

enum State {
	DEPLOY_P1,
	DEPLOY_P2,
	IDLE,
	CHARACTER_SELECTED,
	SELECTING_ATTACK_TARGET,
	SELECTING_RUN_TARGET,
	CHARACTER_MOVING
}

var current_state_plus: GameState = null

var states = {}

@onready var state_container = $States as Node
		
var selected_character: Node2D = null

var current_player_turn: int = 1

var current_round: int = 0:
	set(value):
		current_round = value
		update_round_ui()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	p1_troops_to_deploy = [tank_scene, mid_scene, ranged_scene]
	p2_troops_to_deploy = [tank_scene, mid_scene, ranged_scene]

	states = {
		State.DEPLOY_P1: DeployP1State.new(),
		State.DEPLOY_P2: DeployP2State.new(),
		State.IDLE: IdleState.new(),
		State.CHARACTER_MOVING: CharacterMovingState.new(),
		State.CHARACTER_SELECTED: CharacterSelectState.new(),
		State.SELECTING_ATTACK_TARGET: SelectingAttackTargetState.new(),
		State.SELECTING_RUN_TARGET: SelectingRunTargetState.new()
	}

	for state in states.values():
		state.controller = self
		state_container.add_child(state)
	
	transition_to(State.DEPLOY_P1)

func transition_to(state: State) -> void:
	if !states.has(state):
		print("State not found: %s" % str(state))
		return

	if current_state_plus != null:
		current_state_plus.exit()

	current_state_plus = states[state]
	current_state_plus.enter()
	update_turn_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_pos_local = tilemap.get_local_mouse_position()
	
	hovered_grid_pos = tilemap.local_to_map(mouse_pos_local)
	
	var tile_world_pos = tilemap.map_to_local(hovered_grid_pos)
	
	selector.position = tile_world_pos

func _input(_event: InputEvent) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if current_state_plus is CharacterMovingState:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_state_plus is DeployP1State:
				handle_deploy_command(hovered_grid_pos, 1)
			elif current_state_plus is DeployP2State:
				handle_deploy_command(hovered_grid_pos, 2)
			elif current_state_plus is IdleState:
				handle_character_selection(event.position)
			elif current_state_plus is CharacterSelectState:
				handle_move_command(event.position)
			elif current_state_plus is SelectingAttackTargetState:
				handle_attack_command(hovered_grid_pos)
			elif current_state_plus is SelectingRunTargetState:
				handle_run_command(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_state_plus is CharacterSelectState:
				deselect_character()

func clear_highlight() -> void:
	if highlight_layer:
		highlight_layer.clear()

func show_movement_range(character: Node2D) -> void:
	clear_highlight()
	
	var start_pos: Vector2i = tilemap.local_to_map(character.global_position)
	var max_range: int = character.get("movement_range")
	
	var valid_tiles = []
	
	tilemap.astargrid.set_point_solid(start_pos, false)
	
	for x in range(start_pos.x - max_range, start_pos.x + max_range + 1):
		for y in range(start_pos.y - max_range, start_pos.x + max_range + 1):
			var target_pos = Vector2i(x, y)
			
			if target_pos == start_pos:
				continue
			
			var path: PackedVector2Array = tilemap.astargrid.get_point_path(start_pos, target_pos)
			
			if path.is_empty():
				continue
			
			var path_cost = path.size() - 1
			
			if path_cost > max_range:
				continue
			
			valid_tiles.append(target_pos)
		
		tilemap.astargrid.set_point_solid(start_pos, true)
		
		for tile in valid_tiles:
			highlight_layer.set_cell(tile, HIGHLIGHT_SOURCE_ID, HIGHLIGHT_ATLAS_COORDS)

func show_attack_range() -> void:
	clear_highlight()
	
	var max_range = selected_character.stats.primary_attack_range
	var start_pos: Vector2i = tilemap.local_to_map(selected_character.global_position)

	for x in range(start_pos.x - max_range, start_pos.x + max_range + 1):
		for y in range(start_pos.y - max_range, start_pos.x + max_range + 1):
			var target_pos = Vector2i(x, y)
			
			var distance = start_pos.distance_to(target_pos)
			if distance <= max_range:
				highlight_layer.set_cell(target_pos, ATTACK_HIGHLIGHT_SOURCE_ID, ATTACK_HIGHLIGHT_ATLAS_COORDS)

func start_new_round():
	current_round += 1
	print("Starting Round %d" % current_round)

	for unit in get_tree().get_nodes_in_group("Player1Units"):
		unit.on_round_start()
	for unit in get_tree().get_nodes_in_group("Player2Units"):
		unit.on_round_start()
	
	current_player_turn = 1
	start_player_turn()

func start_player_turn():
	print("Starting Player %d's turn." % current_player_turn)
	var group_name = "Player%dUnits" % current_player_turn
	if get_tree().get_nodes_in_group(group_name).size() == 0:
		print("Player %d has no units left to act." % current_player_turn)
		end_player_turn()
		return

	if check_if_all_characters_acted_by_player(current_player_turn):
		if current_player_turn == 2:
			start_new_round()
		else:
			_change_turn()
		return

	print("Player %d's turn started." % current_player_turn)
	transition_to(State.IDLE)
	update_turn_ui()
	
func handle_character_selection(mouse_position: Vector2) -> void:
	var space_state = get_world_2d().direct_space_state

	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_position
	query.collide_with_areas = true
	query.collision_mask = SELECTABLE_LAYER

	var results = space_state.intersect_point(query)

	if results.size() > 0:
		var selected_node = results[0].collider

		if selected_node.has_method("select"):
			if selected_node.get("player_id") != current_player_turn:
				print("Cannot select character: Not player's turn")
				return

			if selected_node.get("has_acted_this_round"):
				print("Cannot select character: Character has already acted this round")
				return

			selected_character = selected_node
			selected_node.select()

			selected_character.actions_exhausted.connect(_on_actions_exhausted)
			selected_character.move_finished.connect(_on_character_move_finished)

			transition_to(State.CHARACTER_SELECTED)
			print("Character selected: %s" % selected_character.name)

			# show_movement_range(selected_character)
	
func update_tile_occupation(from_pos: Vector2i, to_pos: Vector2i, character: Node2D):
	occupied_tiles.erase(from_pos)
	tilemap.astargrid.set_point_solid(from_pos, false)
	
	occupied_tiles[to_pos] = character
	tilemap.astargrid.set_point_solid(to_pos, true)

func handle_move_command(_mouse_position: Vector2) -> void:
	if selected_character == null:
		return

	var player_grid_pos = tilemap.local_to_map(selected_character.global_position)
	var target_grid_pos = hovered_grid_pos
	
	var path: PackedVector2Array = tilemap.astargrid.get_point_path(player_grid_pos, target_grid_pos)
	
	if path.is_empty():
		print("Nenhum caminho disponivel.")
		return
	
	var path_cost = path.size() - 1
	
	if path_cost == 0:
		deselect_character()
		return
	
	var max_move = selected_character.get("movement_range")
	
	if path_cost > max_move:
		print("Nao e possivel ir para la")
		return
	
	if occupied_tiles.has(path[-1]):
		print("Posicao final ja ocupada.")
		return
	
	update_tile_occupation(player_grid_pos, target_grid_pos, selected_character)
	
	transition_to(State.CHARACTER_MOVING)
	selected_character.move(path)

func handle_attack_command(target_grid_pos: Vector2i) -> void:
	if selected_character == null:
		return

	if !occupied_tiles.has(target_grid_pos):
		print("No target at selected position.")
		deselect_character()
		return

	var target_character = occupied_tiles[target_grid_pos]

	if target_character.get("player_id") == selected_character.get("player_id"):
		print("Cannot attack friendly unit.")
		return
	
	var start_pos: Vector2i = tilemap.local_to_map(selected_character.global_position)
	var distance = start_pos.distance_to(target_grid_pos)
	var max_range = selected_character.stats.primary_attack_range
	
	if distance > max_range:
		print("Target out of range.")
		return
	
	print("Attacking target at %s" % str(target_grid_pos))
	selected_character.attack(target_character)
	
	deselect_character()

func handle_run_command(_mouse_position: Vector2) -> void:
	if selected_character == null:
		return
	
	if selected_character == null:
		return

	var player_grid_pos = tilemap.local_to_map(selected_character.global_position)
	var target_grid_pos = hovered_grid_pos
	
	var path: PackedVector2Array = tilemap.astargrid.get_point_path(player_grid_pos, target_grid_pos)
	
	if path.is_empty():
		print("Nenhum caminho disponivel.")
		return
	
	var path_cost = path.size() - 1
	
	if path_cost == 0:
		deselect_character()
		return
	
	var max_move = selected_character.get("movement_range")
	
	if path_cost > max_move:
		print("Nao e possivel ir para la")
		return
	
	if occupied_tiles.has(path[-1]):
		print("Posicao final ja ocupada.")
		return
	
	update_tile_occupation(player_grid_pos, target_grid_pos, selected_character)
	
	transition_to(State.CHARACTER_MOVING)
	selected_character.run(path)

func deselect_character() -> void:
	clear_highlight()
	
	if selected_character:
		if selected_character.get("can_use_standard_action") and !selected_character.get("can_use_move_action"):
			transition_to(State.CHARACTER_SELECTED)
			return

		if selected_character.move_finished.is_connected(_on_character_move_finished):
			selected_character.move_finished.disconnect(_on_character_move_finished)

		if selected_character.actions_exhausted.is_connected(_on_actions_exhausted):
			selected_character.actions_exhausted.disconnect(_on_actions_exhausted)

		selected_character.deselect()
		selected_character = null
		transition_to(State.IDLE)

		print("Character deselected")

func check_if_all_characters_acted_by_player(player_id: int) -> bool:
	for unit in get_tree().get_nodes_in_group("Player%dUnits" % player_id):
		if !unit.get("has_acted_this_round"):
			return false
	return true

func _change_turn() -> void:
	if current_player_turn == 1:
		current_player_turn = 2
	else:
		current_player_turn = 1

	print("Now it's Player %d's turn" % current_player_turn)
	
	update_turn_ui()
	start_player_turn()

func _on_character_move_finished() -> void:
	if selected_character == null:
		transition_to(State.IDLE)
		return
	
	if !selected_character.get("can_use_standard_action"):
		print("Character has used all actions this turn.")
		deselect_character()
		_change_turn()
		return
	else:
		transition_to(State.CHARACTER_SELECTED)

func handle_deploy_command(map_coords: Vector2i, player_id: int) -> void:
	var target_layer: TileMapLayer
	var troops_left: int
	
	if player_id == 1:
		target_layer = spawn_layer_p1
		troops_left = p1_troops_to_deploy.size()
	else:
		target_layer = spawn_layer_p2
		troops_left = p2_troops_to_deploy.size()
	
	if troops_left <= 0:
		return
	
	if target_layer.get_cell_tile_data(map_coords) == null:
		print("Não é uma zona de spawn.")
		return
	
	if occupied_tiles.has(map_coords):
		print("Posição inválida.")
		return

	var new_troop = null
	if player_id == 1:
		new_troop = p1_troops_to_deploy[0].instantiate()
		new_troop.add_to_group("Player1Units")
	else:
		new_troop = p2_troops_to_deploy[0].instantiate()
		new_troop.add_to_group("Player2Units")
	new_troop.player_id = player_id
	new_troop.tilemap = tilemap

	new_troop.died.connect(_on_character_died)

	add_child(new_troop)
	
	new_troop.global_position = tilemap.map_to_local(map_coords)
	
	occupied_tiles[map_coords] = new_troop
	tilemap.astargrid.set_point_solid(map_coords, true)
	
	if player_id == 1:
		p1_troops_to_deploy.pop_front()
		transition_to(State.DEPLOY_P2)
		if p1_troops_to_deploy.size() == 0:
			return
	else:
		p2_troops_to_deploy.pop_front()
		transition_to(State.DEPLOY_P1)
		if p2_troops_to_deploy.size() == 0:
			start_new_round()
	
func update_turn_ui() -> void:
	if turn_label:
		if current_state_plus is DeployP1State:
			var p1_next_name = ""
			if p1_troops_to_deploy.size() > 0:
				p1_next_name = p1_troops_to_deploy[0].instantiate().stats.character_name
			turn_label.text = "Player 1: Posicione sua tropa <%s>" % p1_next_name
		elif current_state_plus is DeployP2State:
			var p2_next_name = ""
			if p2_troops_to_deploy.size() > 0:
				p2_next_name = p2_troops_to_deploy[0].instantiate().stats.character_name
			turn_label.text = "Player 2: Posicione sua tropa <%s>" % p2_next_name
		elif current_state_plus is IdleState:
			turn_label.text = "Turno do Player %d" % current_player_turn

func update_round_ui() -> void:
	if round_label:
		round_label.text = "Round %d" % current_round

func _on_actions_exhausted() -> void:
	print("Character has exhausted all actions this turn.")
	selected_character.inactive_for_round()
	
	end_player_turn()

func end_player_turn() -> void:
	deselect_character()
	_change_turn()

func _on_attack_button_pressed() -> void:
	if !(current_state_plus is CharacterSelectState):
		print("No character selected to attack.")
		return

	if selected_character == null:
		print("No character selected to attack.")
		return

	print("Attack action initiated for character %s." % selected_character.name)
	print("Transitioning to SelectingAttackTargetState.")
	transition_to(State.SELECTING_ATTACK_TARGET)


func _on_run_button_pressed() -> void:
	if !(current_state_plus is CharacterSelectState):
		print("No character selected to run.")
		return
	
	if selected_character == null:
		print("No character selected to run.")
		return

	print("Run action initiated for character %s." % selected_character.name)
	transition_to(State.SELECTING_RUN_TARGET)

func _on_character_died(character: Node2D) -> void:
	print("Character %s has died. Updating occupied tiles." % character.name)
	
	var char_grid_pos = tilemap.local_to_map(character.global_position)
	if occupied_tiles.has(char_grid_pos):
		occupied_tiles.erase(char_grid_pos)
		tilemap.astargrid.set_point_solid(char_grid_pos, false)

	if character == selected_character:
		deselect_character()
	
	call_deferred("_check_game_over", character.player_id)

func _check_game_over(dead_player_id: int) -> void:
	var remaining_units = get_tree().get_nodes_in_group("Player%dUnits" % dead_player_id)

	if remaining_units.size() == 0:
		var winner_id = 3 - dead_player_id
		print("Player %d has no remaining units. Player %d wins!" % [dead_player_id, 3 - dead_player_id])
		
		get_tree().paused = true
		
		var victory_scene = load("res://menus/end_screen.tscn").instantiate()
		
		victory_scene.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		
		victory_scene.set_winner(winner_id)
		get_tree().root.add_child(victory_scene)
