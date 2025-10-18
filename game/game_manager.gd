extends Node

@export var tilemap: TileMapLayer
@export var selector: Sprite2D
@export var player: Node2D

var hovered_grid_pos: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mouse_pos_local = tilemap.get_local_mouse_position()
	
	hovered_grid_pos = tilemap.local_to_map(mouse_pos_local)
	
	var tile_world_pos = tilemap.map_to_local(hovered_grid_pos)
	
	selector.position = tile_world_pos

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var player_grid_pos = tilemap.local_to_map(player.global_position)
			var target_grid_pos = hovered_grid_pos

			var target_world_post = tilemap.map_to_local(target_grid_pos)
			print("Left clicked on grid position: %s, world position: %s" % [target_grid_pos, target_world_post])

			var path: PackedVector2Array = tilemap.astargrid.get_point_path(
				player_grid_pos,
				target_grid_pos
			)

			if player.has_method("move_to_position"):
				# player.move_to_position(target_world_post)
				pass
			
			if player.has_method("move_along_path"):
				player.move_along_path(path)
