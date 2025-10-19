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
@export var animations_p1: SpriteFrames
@export var animations_p2: SpriteFrames
@export var character_icon: Texture2D
@export var player_color: Color = Color.WHITE
@export var special_ability_button_icon: Texture2D

@export_group("Abilities")
@export var special_ability: SpecialAbility
