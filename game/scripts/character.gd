extends Node2D
class_name Character

@export var tilemap: TileMapLayer
@export var player_id: int
@export var stats: CharacterStats

@export var p1_color: Color = Color.RED
@export var p2_color: Color = Color.BLUE

@export var movement_range: int = 3

signal move_finished


var move_speed: float = 100.0
var current_tween: Tween = null

signal actions_exhausted

var can_use_move_action: bool = true:
	set(value):
		can_use_move_action = value
		if !can_use_move_action and !can_use_standard_action:
			emit_signal("actions_exhausted")
var can_use_standard_action: bool = true:
	set(value):
		can_use_standard_action = value
		if !can_use_move_action and !can_use_standard_action:
			emit_signal("actions_exhausted")

@onready var selection_visual = $SelectionCircle
@onready var sprite: Sprite2D = $Sprite2D

func select():
	selection_visual.visible = true

func deselect():
	selection_visual.visible = false

func apply_stats(stats_to_apply: CharacterStats) -> void:
	if sprite and stats_to_apply.sprite_texture:
		sprite.texture = stats_to_apply.sprite_texture
		print("Applied sprite texture for %s" % stats_to_apply.character_name)
	
	movement_range = stats_to_apply.movement_range

func on_turn_start() -> void:
	can_use_move_action = true
	can_use_standard_action = true
	print("Character's turn started. Actions reset.")

func move(path: PackedVector2Array) -> void:
	if !can_use_move_action:
		push_warning("Move action already used this turn!")
		return

	move_along_path(path)
	
	can_use_move_action = false
	print("Character moved. Move action used.")


func attack() -> void:
	if !can_use_standard_action:
		push_warning("Standard action already used this turn!")
		return
	
	can_use_standard_action = false
	print("Character attacked. Standard action used.")

func run(path: PackedVector2Array) -> void:
	if !can_use_standard_action:
		push_warning("Run action already used this turn!")
		return
	
	can_use_standard_action = false
	print("Character is running. Run action used.")

func special_attack(target: Character) -> void:
	if !can_use_standard_action:
		push_warning("Special attack action already used this turn!")
		return
	
	can_use_standard_action = false
	print("Character is performing special attack on target %s. Standard action used." % target.stats.character_name)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if stats == null:
		push_error("CharacterStats not assigned for character!")
		return
	
	apply_stats(stats)
	print("Character %s ready with stats applied." % stats.character_name)

	# if player_id == 1:
	# 	# modulate = p1_color
	# 	$Sprite2D.texture = preload("res://assets/palhaço_1.png")
	# else:
	# 	# modulate = p2_color
	# 	$Sprite2D.texture = preload("res://assets/palhaço_2.png")

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
