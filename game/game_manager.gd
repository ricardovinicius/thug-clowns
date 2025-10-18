extends Node2D

@export var tilemap: TileMapLayer
@export var selector: Sprite2D
@export var turn_label: Label

var hovered_grid_pos: Vector2i

const SELECTABLE_LAYER = 2

enum State {
	IDLE,
	CHARACTER_SELECTED,
	CHARACTER_MOVING
}

var current_state = State.IDLE
var selected_character: Node2D = null

var current_player_turn: int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_turn_ui()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_pos_local = tilemap.get_local_mouse_position()
	
	hovered_grid_pos = tilemap.local_to_map(mouse_pos_local)
	
	var tile_world_pos = tilemap.map_to_local(hovered_grid_pos)
	
	selector.position = tile_world_pos

func _input(event: InputEvent) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	if current_state == State.CHARACTER_MOVING:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			match current_state:
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

func handle_move_command(mouse_position: Vector2) -> void:
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

func update_turn_ui() -> void:
	if turn_label:
		turn_label.text = "Player %d's Turn" % current_player_turn
