extends StatusEffect
class_name BleedEffect

@export var damage_per_activation: int = 5

func _init():
    effect_name = "Bleed"
    duration_in_rounds = 3

func on_activation():
    super.on_activation()

    print("%s takes %d bleed damage!" % [char_owner.stats.character_name, damage_per_activation])
    char_owner.take_damage(damage_per_activation)
