extends CanvasLayer

@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var restart_btn: Button = $Panel/VBox/RestartButton

func _ready() -> void:
	hide()
	GameManager.game_over.connect(_on_game_over)

func _on_game_over(player_won: bool) -> void:
	result_label.text = "Victory!" if player_won else "Defeated!"
	show()

func _on_restart_pressed() -> void:
	GameManager.wood = 0
	GameManager.stone = 0
	GameManager.gold = 10.0
	GameManager.gold_income_rate = 1.0
	GameManager.troop_count = 0
	get_tree().reload_current_scene()
