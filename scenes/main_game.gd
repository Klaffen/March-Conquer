extends Node

@export var entities: Node2D

var troop_scene: PackedScene = load("res://scenes/units/troop.tscn")

# Enemy troop production (the player recruits via the selected building's queue).
func spawn_troop(player: bool) -> bool:
	if player:
		return false

	var portal: Node = get_node_or_null("World/level/Portal")
	if portal == null:
		return false

	var troop: Troop = troop_scene.instantiate()
	troop.global_position = portal.global_position
	troop.is_player_troop = false
	entities.add_child(troop)
	return true
