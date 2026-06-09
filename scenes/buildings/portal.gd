extends Node2D

@export var max_hp: int = 100

var hp: int

@onready var hp_bar: ProgressBar = $HPBar


signal portal_destroyed

func _ready() -> void:
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	add_to_group("obstacles")
	add_to_group("enemy_castle")
	$SpawnTimer.timeout.connect(_on_spawn_timer_timeout)


func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	hp_bar.value = hp
	if hp <= 0:
		portal_destroyed.emit()
		GameManager.end_game(true)

func _on_spawn_timer_timeout() -> void:
	get_tree().root.get_node("MainGame").spawn_troop(false)
