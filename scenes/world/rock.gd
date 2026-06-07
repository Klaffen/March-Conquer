extends "res://scenes/world/resource_node.gd"

func _ready() -> void:
	yield_type = "stone"
	yield_amount = 5
	super._ready()
