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
var current_health: int:
	set(value):
		current_health = value
		_update_health_label()

signal actions_exhausted
signal died(character)

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
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_label: Label = $HealthLabel
@onready var status_effect_container: Node = $StatusEffectContainer

func select():
	selection_visual.visible = true

func deselect():
	selection_visual.visible = false

func apply_stats(stats_to_apply: CharacterStats) -> void:
	if sprite:
		if player_id == 1:
			sprite.frames = stats_to_apply.animations_p1
		else:
			sprite.frames = stats_to_apply.animations_p2
			sprite.flip_h = true
		sprite.play("idle")
	
	movement_range = stats_to_apply.movement_range
	current_health = stats_to_apply.max_health
	_update_health_label()

var has_acted_this_round: bool = false

func apply_status_effect(effect_instance: StatusEffect) -> void:
	status_effect_container.add_child(effect_instance)
	effect_instance.on_apply(self)
	print("Applied status effect: %s" % effect_instance.effect_name)

func _activate_status_effects() -> void:
	for effect in status_effect_container.get_children():
		if effect is StatusEffect:
			effect.on_activation()
			effect.on_round_tick()
			print("Activated status effect: %s" % effect.effect_name)

func on_round_start() -> void:
	active_for_round()
	_activate_status_effects()
	print("Character's round started. Actions reset.")

func inactive_for_round() -> void:
	has_acted_this_round = true
	modulate.a = 0.5
	print("Character is inactive for this round.")

func active_for_round() -> void:
	can_use_move_action = true
	can_use_standard_action = true
	has_acted_this_round = false
	modulate = Color(1, 1, 1)
	print("Character is active for this round.")

func move(path: PackedVector2Array) -> void:
	if !can_use_move_action:
		push_warning("Move action already used this turn!")
		return

	move_along_path(path)
	
	can_use_move_action = false
	print("Character moved. Move action used.")


func attack(target: Node2D) -> void:
	if !can_use_standard_action:
		push_warning("Standard action already used this turn!")
		return
	
	sprite.play("attack")

	if target and target.has_method("take_damage"):
		target.take_damage(stats.attack_power)
	
	can_use_standard_action = false
	print("Character attacked. Standard action used.")

func run(path: PackedVector2Array) -> void:
	if !can_use_standard_action:
		push_warning("Standard action already used this turn!")
		return

	move_along_path(path)
	
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

func _activate_damage_modifiers(amount: int) -> int:
	var modified_amount = amount
	
	for effect in status_effect_container.get_children():
		if effect is StatusEffect:
			modified_amount = effect.modify_damage_taken(modified_amount)
			print("Modified damage by effect %s. New damage: %d" % [effect.effect_name, modified_amount])
	
	return modified_amount

func take_damage(amount: int) -> void:
	var modified_damage = _activate_damage_modifiers(amount)

	current_health -= modified_damage
	print("Character took %d damage. Current health: %d" % [modified_damage, current_health])
	if current_health <= 0:
		die()

func _clean_effects_on_death() -> void:
	for effect in status_effect_container.get_children():
		if effect is StatusEffect:
			effect.on_removed()
			effect.queue_free()
			print("Removed status effect on death: %s" % effect.effect_name)

func die() -> void:
	print("Character %s has died." % stats.character_name)

	died.emit(self)

	_clean_effects_on_death()
	
	if player_id == 1:
		remove_from_group("Player1Units")
	else:
		remove_from_group("Player2Units")

	queue_free()

func use_special_ability(targets: Array) -> void:
	if !can_use_standard_action:
		push_warning("Standard action already used this turn!")
		return

	if stats.special_ability == null:
		push_warning("No special ability assigned to character %s!" % stats.character_name)
		return

	stats.special_ability.execute(self, targets)
	can_use_standard_action = false
	print("Character %s used special ability %s on target %s." % [stats.character_name, stats.special_ability.ability_name, targets[0].stats.character_name])

func _update_health_label() -> void:
	health_label.text = "%d/%d" % [current_health, stats.max_health]
