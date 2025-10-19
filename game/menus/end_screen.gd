extends Control

@onready var winner_label : Label = $WinnerLabel
@onready var menu_button : Button = $MenuButton

var winner_id : int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu_button.pressed.connect(_on_menu_button_pressed)
	
	if winner_id > 0:
		winner_label.text = "Jogador %d venceu" % winner_id
	else:
		winner_label.text = "Fim de jogo"

func set_winner(id: int) -> void:
	winner_id = id
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
