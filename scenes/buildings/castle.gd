extends Node2D

@export var max_hp: int = 100
@export var is_player_castle: bool = true

var hp: int

@onready var hp_bar: ProgressBar = $HPBar
@onready var castle_sprite: Sprite2D = $CastleSprite

signal castle_destroyed

func _ready() -> void:
	hp = max_hp
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	if is_player_castle:
		add_to_group("player_castle")
	else:
		castle_sprite.texture = load("res://assets/sprites/buildings/Inn_Red.png")
		add_to_group("enemy_castle")

func take_damage(amount: int) -> void:
	hp = max(0, hp - amount)
	hp_bar.value = hp
	if hp <= 0:
		castle_destroyed.emit()
		GameManager.end_game(false)
