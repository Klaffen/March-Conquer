extends Node2D
class_name Barracks

@export var troop_scene: PackedScene = load("res://scenes/units/troop.tscn")
@export var build_item_scene: PackedScene = load("res://scenes/buildings/build_item.tscn")
@export var ghost: bool = false

@export var knight_icon: CompressedTexture2D = load("res://assets/sprites/npcs/knight_icon.png")

const COST: Dictionary = {"wood": 10, "stone": 5}

enum State { IDLE, JUST_PRODUCED_IDLE, PRODUCING, JUST_PRODUCED_PRODUCING }

const REGION_W: float = 112.0
const REGION_H: float = 144.0
const REGIONS: Array[Rect2] = [
	Rect2(REGION_W * 0, 0, REGION_W, REGION_H),  # just produced, now idle
	Rect2(REGION_W * 1, 0, REGION_W, REGION_H),  # idle
	Rect2(REGION_W * 2, 0, REGION_W, REGION_H),  # just produced, still producing
	Rect2(REGION_W * 3, 0, REGION_W, REGION_H),  # still producing
]

const JUST_PRODUCED_DURATION: float = 1.0

const income: float = 0.25

@onready var sprite: Sprite2D = $Sprite2D
@onready var build_queue: Node = $BuildQueue

var state: State = State.IDLE
var _just_produced_timer: float = 0.0

func _ready() -> void:
	build_queue.finished_item.connect(_spawn_unit)

func _process(delta: float) -> void:
	if ghost:
		return

	if _just_produced_timer > 0.0:
		_just_produced_timer -= delta
		if _just_produced_timer <= 0.0:
			_just_produced_timer = 0.0
			_update_state()

# Queues a unit for production. Omit the arguments to build the default troop;
# pass a scene/icon/time to produce any other unit type.
func add_to_queue(unit_scene: PackedScene = null, icon: Texture2D = null, time: float = 10.0) -> void:
	if unit_scene == null:
		unit_scene = troop_scene
	if icon == null:
		icon = knight_icon

	var build_item: BuildItem = build_item_scene.instantiate()
	build_item.initialize(unit_scene, icon, time)

	if not build_queue.add(build_item):
		build_item.queue_free()
		return

	_update_state()


func _spawn_unit(unit_scene: PackedScene) -> void:
	if unit_scene == null:
		return

	var unit: Node2D = unit_scene.instantiate()
	var door: Node2D = get_node_or_null("Door")
	unit.global_position = door.global_position if door != null else global_position
	get_tree().root.get_node("MainGame/World/Entities").add_child(unit)
	_just_produced_timer = JUST_PRODUCED_DURATION
	_update_state()

	GameManager.gold_income_rate += income

# The state is fully derived from two facts: whether the queue still has work,
# and whether we're inside the brief "just produced" flash window.
func _update_state() -> void:
	var producing: bool = not build_queue.is_empty()
	var just_produced: bool = _just_produced_timer > 0.0

	var new_state: State
	if just_produced:
		new_state = State.JUST_PRODUCED_PRODUCING if producing else State.JUST_PRODUCED_IDLE
	else:
		new_state = State.PRODUCING if producing else State.IDLE

	if new_state == state:
		return

	state = new_state
	match state:
		State.JUST_PRODUCED_IDLE:       sprite.region_rect = REGIONS[0]
		State.IDLE:                     sprite.region_rect = REGIONS[1]
		State.JUST_PRODUCED_PRODUCING:  sprite.region_rect = REGIONS[2]
		State.PRODUCING:                sprite.region_rect = REGIONS[3]
