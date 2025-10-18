extends TileMapLayer

var astargrid = AStarGrid2D.new()

func setup_astargrid() -> void:
	astargrid.region = get_used_rect()
	# astargrid.cell_size = tile_set.tile_size
	astargrid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astargrid.update()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_astargrid()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
