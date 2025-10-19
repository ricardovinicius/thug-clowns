# Em ApplyDebuffAbility.gd
extends SpecialAbility
class_name DebuffTargetBleedAbility

# @export var bleed_effect: StatusEffect

func _init():
    targeting_type = TargetingType.ENEMY
    range = 2 # "adjacente e a 2 tiles"
    ability_name = "Causar Sangramento"

func execute(owner: Character, targets: Array) -> void:
    print("%s usa %s!" % [owner.stats.character_name, ability_name])

    if targets.is_empty():
        return

    var target = targets[0] as Character
    # target.apply_status_effect(bleed_effect.new())

    # Simulação:
    target.modulate = Color.RED
    print("%s está sangrando!" % target.stats.character_name)