extends Node2D
class_name Barracks

@export var troop_scene: PackedScene
@export var ghost: bool = false

const COST := {"wood": 10, "stone": 5}

enum State { IDLE, JUST_PRODUCED_IDLE, PRODUCING, JUST_PRODUCED_PRODUCING }

const REGION_W := 114.846436
const REGION_H := 144.0
const REGIONS: Array[Rect2] = [
	Rect2(REGION_W * 0, 0, REGION_W, REGION_H),  # just produced, now idle
	Rect2(REGION_W * 1, 0, REGION_W, REGION_H),  # idle
	Rect2(REGION_W * 2, 0, REGION_W, REGION_H),  # just produced, still producing
	Rect2(REGION_W * 3, 0, REGION_W, REGION_H),  # still producing
]

const JUST_PRODUCED_DURATION := 1.0

@onready var sprite: Sprite2D = $Sprite2D

var state: State = State.IDLE
var is_producing: bool = false
var _just_produced_timer: float = 0.0

func _process(delta: float) -> void:
	if ghost:
		return
	if state == State.JUST_PRODUCED_IDLE or state == State.JUST_PRODUCED_PRODUCING:
		_just_produced_timer -= delta
		if _just_produced_timer <= 0.0:
			_set_state(State.PRODUCING if is_producing else State.IDLE)

func spawn_troop() -> void:
	if troop_scene == null:
		return
	var troop = troop_scene.instantiate()
	troop.global_position = global_position
	get_tree().root.get_node("MainGame/World/Entities").add_child(troop)
	_just_produced_timer = JUST_PRODUCED_DURATION
	_set_state(State.JUST_PRODUCED_PRODUCING if is_producing else State.JUST_PRODUCED_IDLE)

func _set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.JUST_PRODUCED_IDLE:       sprite.region_rect = REGIONS[0]
		State.IDLE:                     sprite.region_rect = REGIONS[1]
		State.JUST_PRODUCED_PRODUCING:  sprite.region_rect = REGIONS[2]
		State.PRODUCING:                sprite.region_rect = REGIONS[3]
