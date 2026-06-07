extends Node2D
class_name Woodhut

@export var ghost: bool = false
@export var woodsman_scene: PackedScene = load("res://scenes/units/woodsman.tscn")
@export var build_item_scene: PackedScene = load("res://scenes/buildings/build_item.tscn")
@export var woodsman_icon: Texture2D = load("res://assets/sprites/npcs/lumberjack_icon.png")

const COST: Dictionary = {"wood": 10, "stone": 0}

@onready var build_queue: Node = $BuildQueue

func _ready() -> void:
	build_queue.finished_item.connect(_spawn_unit)

func add_to_queue() -> void:
	var build_item: BuildItem = build_item_scene.instantiate()
	build_item.initialize(woodsman_scene, woodsman_icon)

	if not build_queue.add(build_item):
		build_item.queue_free()

func _spawn_unit(unit_scene: PackedScene) -> void:
	if unit_scene == null:
		return

	var unit: Node2D = unit_scene.instantiate()
	var door: Node2D = get_node_or_null("Door")
	unit.global_position = door.global_position if door != null else global_position
	get_tree().root.get_node("MainGame/World/Entities").add_child(unit)
