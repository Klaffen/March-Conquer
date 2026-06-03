extends Node

@export var entities: Node2D
var woodsman_scene = load("res://scenes/woodsman.tscn")
var miner_scene = load("res://scenes/miner.tscn")

func spawn_worker(player: bool, is_woodsman: bool) -> void:
	if (player):
		print("Spawning worker for the player")
		var worker: Worker = woodsman_scene.instantiate() if is_woodsman else miner_scene.instantiate()
		var woodhut: Node = get_node("World/level/Woodhut")
		worker.global_position = woodhut.get_node("Door").global_position
		entities.add_child(worker)
	else:
		print("Spawning worker for the enemy")
