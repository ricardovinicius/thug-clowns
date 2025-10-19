extends Node
class_name StatusEffect

var char_owner: Character

@export var effect_name: String = "Unnamed Effect"
@export var duration_in_rounds: int = 1

func on_apply(target: Character) -> void:
    char_owner = target
    print("%s applied to %s" % [effect_name, target.stats.character_name])

func on_activation():
    pass

func on_removed():
    print("%s removed from %s" % [effect_name, char_owner.stats.character_name])

func on_round_tick():
    if duration_in_rounds > 0:
        duration_in_rounds -= 1
        print("%s duration decreased to %d rounds" % [effect_name, duration_in_rounds])
        if duration_in_rounds <= 0:
            queue_free()

func modify_damage_taken(damage: int) -> int:
    return damage