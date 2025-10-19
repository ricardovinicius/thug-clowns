extends StatusEffect
class_name ResistanceEffect

@export var damage_reduction: int = 5

func _init():
    effect_name = "Resistência"

func modify_damage_taken(damage: int) -> int:
    print("%s reduces damage taken by %d" % [effect_name, damage_reduction])
    var modified_damage = max(damage - damage_reduction, 0)
    return modified_damage