# Em BuffSelfAbility.gd
extends SpecialAbility
class_name BuffSelfAbility

# Você pode exportar o efeito que esta habilidade aplica
# @export var resistance_buff: StatusEffect 

func _init():
    # Configura os valores padrão para esta habilidade
    targeting_type = TargetingType.SELF
    range = 0
    ability_name = "Aumentar Resistência"

# Sobrescreve a função 'execute'
func execute(owner: Character, targets: Array) -> void:
    print("%s usa %s!" % [owner.stats.character_name, ability_name])

    # 'owner' é o único alvo em 'targets'
    # owner.apply_status_effect(resistance_buff.new())

    # Por enquanto (sem sistema de status), vamos simular:
    owner.modulate = Color.GOLD # Deixa o personagem dourado
    print("%s está com a resistência aumentada!" % owner.stats.character_name)