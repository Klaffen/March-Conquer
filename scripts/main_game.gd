extends Node

@export var entities: Node2D

var woodsman_scene: PackedScene = load("res://scenes/woodsman.tscn")
var miner_scene: PackedScene = load("res://scenes/miner.tscn")
var troop_scene: PackedScene = load("res://scenes/troop.tscn")

func spawn_worker(player: bool, is_woodsman: bool) -> void:
	if not player:
		return
	var woodhut: Node = get_node_or_null("World/Buildings/Woodhut")
	if woodhut == null:
		return
	var worker: Worker = woodsman_scene.instantiate() if is_woodsman else miner_scene.instantiate()
	worker.global_position = woodhut.get_node("Door").global_position
	entities.add_child(worker)

# Whether a troop can be spawned for the given side right now (building exists).
func can_spawn_troop(player: bool) -> bool:
	if player:
		return get_node_or_null("World/Buildings/Barracks") != null
	return get_node_or_null("World/level/Portal") != null

#TODO: Combine these functions into a generic spawn function
func spawn_troop(player: bool) -> bool:
	if player:
		var barracks: Barracks = get_node_or_null("World/Buildings/Barracks")
		if barracks == null:
			return false
		# Let the barracks handle spawning so its production animation plays.
		barracks.spawn_troop()
		return true
	else:
		var portal: Node = get_node_or_null("World/level/Portal")
		if portal == null:
			return false
		var troop: Troop = troop_scene.instantiate()
		troop.global_position = portal.global_position
		troop.is_player_troop = false
		entities.add_child(troop)
		return true
