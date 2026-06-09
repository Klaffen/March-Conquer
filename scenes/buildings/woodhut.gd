extends Building
class_name Woodhut

@export var ghost: bool = false
@export var woodsman_icon: Texture2D = load("res://assets/sprites/npcs/lumberjack_icon.png")
@export var miner_icon: Texture2D = load("res://assets/sprites/npcs/miner_icon.png")

const WOODSMAN_SCENE: PackedScene = preload("res://scenes/units/woodsman.tscn")
const MINER_SCENE: PackedScene = preload("res://scenes/units/miner.tscn")
const BUILD_ITEM_SCENE: PackedScene = preload("res://scenes/buildings/build_item.tscn")


const COST: Dictionary = {"wood": 10, "stone": 0}

func add_to_queue(is_woodsman: bool = true) -> void:
	var unit_scene: PackedScene = WOODSMAN_SCENE if is_woodsman else MINER_SCENE
	var icon: Texture2D = woodsman_icon if is_woodsman else miner_icon

	var build_item: BuildItem = BUILD_ITEM_SCENE.instantiate()
	build_item.initialize(unit_scene, icon)

	if not build_queue.add(build_item):
		build_item.queue_free()
