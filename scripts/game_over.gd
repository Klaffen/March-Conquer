extends CanvasLayer

@onready var result_label: Label = $Panel/VBox/ResultLabel
@onready var restart_btn: Button = $Panel/VBox/RestartButton

func _ready() -> void:
	# Keep processing while the tree is paused so the restart button stays live.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	GameManager.game_over.connect(_on_game_over)

func _on_game_over(player_won: bool) -> void:
	result_label.text = "Victory!" if player_won else "Defeated!"
	show()
	get_tree().paused = true

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_values()
	get_tree().reload_current_scene()
