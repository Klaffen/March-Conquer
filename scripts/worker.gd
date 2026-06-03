class_name Worker
extends CharacterBody2D

@export var is_player_worker: bool = true
@export var worker_type: GameManager.WorkerTypes

const SPEED: float = 60.0
const HARVEST_RANGE: float = 25.0
const HARVEST_INTERVAL: float = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var target_node: Node = null
var harvest_timer: float = 0.0
var is_harvesting: bool = false

func _ready() -> void:
	_find_nearest_resource()

func _physics_process(delta: float) -> void:
	if target_node == null or not is_instance_valid(target_node):
		_find_nearest_resource()
		if target_node == null:
			_play_animation("idle_front", false)
		return

	var direction = target_node.global_position - global_position
	if direction.length() <= HARVEST_RANGE:
		is_harvesting = true
		harvest_timer += delta
		if harvest_timer >= HARVEST_INTERVAL:
			harvest_timer = 0.0
			target_node.harvest()
		_play_chop_animation(direction)
	else:
		velocity = direction.normalized() * SPEED
		move_and_slide()
		is_harvesting = false
		_play_walk_animation(direction)

func _play_walk_animation(direction: Vector2) -> void:
	if abs(direction.y) >= abs(direction.x):
		_play_animation("walk_up" if direction.y < 0 else "walk_down", false)
	else:
		_play_animation("walk_right", direction.x < 0)

func _play_chop_animation(direction: Vector2) -> void:
	if abs(direction.y) >= abs(direction.x):
		_play_animation("chop_up" if direction.y < 0 else "chop_down", false)
	else:
		_play_animation("chop_right", direction.x < 0)

func _play_animation(anim_name: StringName, flip: bool) -> void:
	sprite.flip_h = flip
	if sprite.animation != anim_name:
		sprite.play(anim_name)

func _find_nearest_resource() -> void:
	var nodes: Array = get_tree().get_nodes_in_group("wood") if worker_type == GameManager.WorkerTypes.WOODSMAN else get_tree().get_nodes_in_group("stone")
	target_node = null
	var min_dist := INF
	for node in nodes:
		if node.is_depleted:
			continue
		var dist = global_position.distance_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			target_node = node
