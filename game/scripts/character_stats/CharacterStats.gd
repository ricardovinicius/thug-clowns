extends Resource
class_name CharacterStats

@export var character_name: String

@export_group("Stats")
@export var max_health: int
@export var attack_power: int
@export var movement_range: int
@export var primary_attack_range: int
@export var secondary_attack_range: int

@export_group("Visuals")
@export var sprite_texture: Texture2D
@export var player_color: Color = Color.WHITE

@export_group("Abilities")
@export var special_ability: SpecialAbility
