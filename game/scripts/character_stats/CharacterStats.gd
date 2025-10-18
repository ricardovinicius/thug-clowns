extends Resource
class_name CharacterStats

@export var character_name: String = "Character"

@export_group("Stats")
@export var max_health: int = 100
@export var attack_power: int = 20
@export var movement_range: int = 2
@export var primary_attack_range: int = 1
@export var secondary_attack_range: int = 1

@export_group("Visuals")    
@export var sprite_texture: Texture2D
@export var player_color: Color = Color.WHITE
