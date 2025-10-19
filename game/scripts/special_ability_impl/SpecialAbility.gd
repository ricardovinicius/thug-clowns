# Em SpecialAbility.gd
extends Resource
class_name SpecialAbility

# Enum para dizer ao GameManager que tipo de mira esta habilidade usa
enum TargetingType {
    SELF,   # Em si mesmo (ex: buff de resistência)
    ENEMY,  # Em um inimigo (ex: sangramento)
    ALLY,   # Em um aliado
    GROUND  # Em um tile do chão
}

@export var ability_name: String = "Special Ability"
@export_multiline var description: String = "Ability description."

@export var targeting_type: TargetingType = TargetingType.ENEMY
@export var range: int = 1 # Alcance (0 para 'SELF')

# A função "virtual" que toda habilidade concreta VAI implementar
# 'owner' é o personagem que está usando a habilidade
# 'targets' é um array (pode ter 1 alvo, ou vários para AoE)
func execute(owner: Character, targets: Array) -> void:
    # 'push_error' é uma boa prática para funções "abstratas"
    push_error("A função 'execute' não foi implementada para %s!" % self.resource_path)