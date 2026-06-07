extends Node

@export var entities: Node2D

var woodsman_scene: PackedScene = load("res://scenes/units/woodsman.tscn")
var miner_scene: PackedScene = load("res://scenes/units/miner.tscn")
var troop_scene: PackedScene = load("res://scenes/units/troop.tscn")

func spawn_worker(player: bool, is_woodsman: bool) -> void:
	if not player:
		return
	var woodhut: Woodhut = get_node_or_null("World/Buildings/Woodhut")
	if woodhut == null:
		return
	if is_woodsman:
		# Let the woodhut produce it through its build queue (shows progress).
		woodhut.add_to_queue()
		return
	# Miners have no production building yet, so spawn them directly.
	var worker: Worker = miner_scene.instantiate()
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
		barracks.add_to_queue()
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
