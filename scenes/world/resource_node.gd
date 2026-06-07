extends Node2D

@export var max_hp: int = 5
@export var yield_type: String = "wood"
@export var yield_amount: int = 5

var hp: int
var is_depleted: bool = false

signal depleted(node: Node)

func _ready() -> void:
	hp = max_hp
	add_to_group(yield_type)


func harvest(amount: int = 1) -> void:
	if is_depleted:
		return
	hp -= amount
	if hp <= 0:
		_on_depleted()

func _on_depleted() -> void:
	is_depleted = true
	if yield_type == "wood":
		GameManager.add_wood(yield_amount)
	elif yield_type == "stone":
		GameManager.add_stone(yield_amount)
	depleted.emit(self)
	queue_free()
