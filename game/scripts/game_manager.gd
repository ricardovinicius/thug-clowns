extends Node2D

@export var tilemap: TileMapLayer
@export var selector: Sprite2D
@export var turn_label: Label
@export var spawn_layer_p1: TileMapLayer
@export var spawn_layer_p2: TileMapLayer
@export var CharacterScene: PackedScene

var p1_troops_to_deploy: int = 3:
	set(value):
		p1_troops_to_deploy = value
		update_turn_ui()
var p2_troops_to_deploy: int = 3:
	set(value):
		p2_troops_to_deploy = value
		update_turn_ui()

var occupied_tiles = {}

var hovered_grid_pos: Vector2i

const SELECTABLE_LAYER = 2

enum State {
	DEPLOY_P1,
	DEPLOY_P2,
	IDLE,
	CHARACTER_SELECTED,
	CHARACTER_MOVING
}

var current_state = State.DEPLOY_P1:
	set(value):
		current_state = value
		update_turn_ui()

var current_state_plus: GameState = null
var states = {}

@onready var state_container = $States as Node
		
var selected_character: Node2D = null

var current_player_turn: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	current_state = State.DEPLOY_P1
	states = {
		State.DEPLOY_P1: DeployP1State.new(),
		State.DEPLOY_P2: DeployP2State.new(),
		State.IDLE: IdleState.new(),
	}
	for state in states.values():
		state.controller = self
		state_container.add_child(state)
	update_turn_ui()
	transition_to(State.DEPLOY_P1)

func transition_to(state: State) -> void:
	if !states.has(state):
		print("State not found: %s" % str(state))
		return

	if current_state_plus != null:
		current_state_plus.exit()

	current_state_plus = states[state]
	current_state_plus.enter()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_pos_local = tilemap.get_local_mouse_position()
	
	hovered_grid_pos = tilemap.local_to_map(mouse_pos_local)
	
	var tile_world_pos = tilemap.map_to_local(hovered_grid_pos)
	
	selector.position = tile_world_pos

func _input(_event: InputEvent) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.CHARACTER_MOVING:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			match current_state:
				State.DEPLOY_P1:
					handle_deploy_command(hovered_grid_pos, 1)
				State.DEPLOY_P2:
					handle_deploy_command(hovered_grid_pos, 2)
				State.IDLE:
					handle_character_selection(event.position)
				State.CHARACTER_SELECTED:
					handle_move_command(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if current_state == State.CHARACTER_SELECTED:
				deselect_character()

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

			selected_character = selected_node
			selected_node.select()

			selected_character.move_finished.connect(_on_character_move_finished)

			current_state = State.CHARACTER_SELECTED
			print("Character selected: %s" % selected_character.name)

func handle_move_command(_mouse_position: Vector2) -> void:
	if selected_character == null:
		return

	var player_grid_pos = tilemap.local_to_map(selected_character.global_position)
	var target_grid_pos = hovered_grid_pos

	var target_world_post = tilemap.map_to_local(target_grid_pos)
	print("Left clicked on grid position: %s, world position: %s" % [target_grid_pos, target_world_post])

	var path: PackedVector2Array = tilemap.astargrid.get_point_path(
		player_grid_pos,
		target_grid_pos
	)
	
	if selected_character.has_method("move_along_path"):
		current_state = State.CHARACTER_MOVING
		print("Moving character along path...")
		selected_character.move_along_path(path)

func deselect_character() -> void:
	if selected_character:
		if selected_character.move_finished.is_connected(_on_character_move_finished):
			selected_character.move_finished.disconnect(_on_character_move_finished)

		selected_character.deselect()
		selected_character = null
		current_state = State.IDLE

		print("Character deselected")

func _on_character_move_finished() -> void:
	deselect_character()

	if current_player_turn == 1:
		current_player_turn = 2
	else:
		current_player_turn = 1

	print("Now it's Player %d's turn" % current_player_turn)
	update_turn_ui()

	current_state = State.IDLE

func handle_deploy_command(map_coords: Vector2i, player_id: int) -> void:
	var target_layer: TileMapLayer
	var troops_left: int
	
	if player_id == 1:
		target_layer = spawn_layer_p1
		troops_left = p1_troops_to_deploy
	else:
		target_layer = spawn_layer_p2
		troops_left = p2_troops_to_deploy
	
	if troops_left <= 0:
		return
	
	if target_layer.get_cell_tile_data(map_coords) == null:
		print("Não é uma zona de spawn.")
		return
	
	if occupied_tiles.has(map_coords):
		print("Posição inválida.")
		return

	var new_troop = CharacterScene.instantiate()
	new_troop.player_id = player_id
	new_troop.tilemap = tilemap

	add_child(new_troop)
	
	new_troop.global_position = tilemap.map_to_local(map_coords)
	
	occupied_tiles[map_coords] = new_troop
	
	if player_id == 1:
		p1_troops_to_deploy -= 1
		current_state = State.DEPLOY_P2
		transition_to(State.DEPLOY_P2)
		update_turn_ui()
		if p1_troops_to_deploy == 0:
			return
	else:
		p2_troops_to_deploy -= 1
		current_state = State.DEPLOY_P1
		transition_to(State.DEPLOY_P1)
		update_turn_ui()
		if p2_troops_to_deploy == 0:
			current_state = State.IDLE
			transition_to(State.IDLE)
			current_player_turn = 1
			update_turn_ui()
	
func update_turn_ui() -> void:
	if turn_label:
		match current_state:
			State.DEPLOY_P1:
				turn_label.text = "Player 1: Posicione suas %d tropas restantes" % p1_troops_to_deploy
			State.DEPLOY_P2:
				turn_label.text = "Player 2: Posicione suas %d tropas restantes" % p2_troops_to_deploy
			State.IDLE:
				turn_label.text = "Turno do Player %d" % current_player_turn
