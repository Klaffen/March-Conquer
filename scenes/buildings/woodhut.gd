extends Building
class_name Woodhut

@export var ghost: bool = false
@export var woodsman_scene: PackedScene = load("res://scenes/units/woodsman.tscn")
@export var miner_scene: PackedScene = load("res://scenes/units/miner.tscn")
@export var build_item_scene: PackedScene = load("res://scenes/buildings/build_item.tscn")
@export var woodsman_icon: Texture2D = load("res://assets/sprites/npcs/lumberjack_icon.png")
@export var miner_icon: Texture2D = load("res://assets/sprites/npcs/miner_icon.png")

const COST: Dictionary = {"wood": 10, "stone": 0}

func add_to_queue(is_woodsman: bool = true) -> void:
	var unit_scene: PackedScene = woodsman_scene if is_woodsman else miner_scene
	var icon: Texture2D = woodsman_icon if is_woodsman else miner_icon

	var build_item: BuildItem = build_item_scene.instantiate()
	build_item.initialize(unit_scene, icon)

	if not build_queue.add(build_item):
		build_item.queue_free()
