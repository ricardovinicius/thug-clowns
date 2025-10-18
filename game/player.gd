extends Node2D

@export var tilemap: TileMapLayer
@export var player_id: int

@export var p1_color: Color = Color.RED
@export var p2_color: Color = Color.BLUE

var move_speed: float = 100.0
var current_tween: Tween = null

signal move_finished

@onready var selection_visual = $SelectionCircle

func select():
	selection_visual.visible = true

func deselect():
	selection_visual.visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if player_id == 1:
		# modulate = p1_color
		$Sprite2D.texture = preload("res://palhaço_1.png")
	else:
		# modulate = p2_color
		$Sprite2D.texture = preload("res://palhaço_2.png")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func move_along_path(path: PackedVector2Array) -> void:
	print("Moving along path: %s" % path)
	
	if path.size() == 0:
		return
	
	if current_tween:
		current_tween.kill()
	
	# 1. Crie um Tween SEQUENCIAL (o padrão)
	current_tween = create_tween()
	
	# 2. Rastreie a posição inicial/anterior
	var last_position = global_position
	
	for grid_pos in path:
		# Converte a coordenada do grid para a posição do mundo
		var target_position = tilemap.map_to_local(grid_pos)
		
		# 3. Calcule a distância do ÚLTIMO ponto até o PRÓXIMO ponto
		var distance = last_position.distance_to(target_position)
		
		# Se o ponto for o mesmo, pule (evita dividir por zero)
		if distance == 0:
			continue
			
		var duration = distance / move_speed
		
		# 4. Adicione a animação à FILA (ela só rodará após a anterior)
		current_tween.tween_property(self, "global_position", target_position, duration)
		
		# 5. Atualize o "último ponto" para o próximo loop
		last_position = target_position
	
	current_tween.finished.connect(func():
		print("Move to position finished")
		emit_signal("move_finished")
	)
