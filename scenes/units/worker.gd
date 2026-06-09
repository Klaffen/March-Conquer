class_name Worker
extends CharacterBody2D

@export var is_player_worker: bool = true
@export var worker_type: GameManager.WorkerTypes

const SPEED: float = 60.0
const HARVEST_RANGE: float = 25.0
const HARVEST_INTERVAL: float = 1.0

const REPATH_INTERVAL: float = 0.5
const WAYPOINT_REACHED_DIST: float = 12.0
# A resource is "unreachable" when the best path ends farther than this from it
# (walled off by a building or other resources); the worker then picks another.
const REACHABLE_DIST: float = 40.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var target_node: Node = null
var harvest_timer: float = 0.0
var is_harvesting: bool = false
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _repath_timer: float = 0.0
var _unreachable: Array[Node] = []

func _ready() -> void:
	add_to_group("workers")
	_find_nearest_resource()
	# Path on the first frame; spawns are staggered in time so workers stay desynced.
	_repath_timer = 0.0

func _physics_process(delta: float) -> void:
	if target_node == null or not is_instance_valid(target_node):
		_find_nearest_resource()
		if target_node == null:
			_play_animation("idle_front", false)
		return

	var goal: Vector2 = target_node.global_position
	var direction: Vector2 = goal - global_position
	if direction.length() <= HARVEST_RANGE:
		is_harvesting = true
		_unreachable.clear()  # reached a resource; forget past failures
		harvest_timer += delta
		if harvest_timer >= HARVEST_INTERVAL:
			harvest_timer = 0.0
			target_node.harvest()
		_play_chop_animation(direction)
		return

	# Follow an A* path around obstacles toward the resource.
	is_harvesting = false
	_repath_timer -= delta
	if _repath_timer <= 0.0:
		_repath_timer = REPATH_INTERVAL
		_path = Pathfinding.find_path(global_position, goal)
		_path_index = 0
		if not _path_reaches(goal):
			# Walled off (e.g. behind a building): drop it and pick another.
			_unreachable.append(target_node)
			_path = PackedVector2Array()
			_find_nearest_resource()
			return

	var step_target: Vector2 = _next_waypoint(goal)
	var to_step: Vector2 = step_target - global_position
	if to_step.length() > 0.5:
		velocity = to_step.normalized() * SPEED
		move_and_slide()
		_play_walk_animation(to_step)

# True if the current path can get the worker within harvest reach of the goal.
# An empty path means start and goal share a cell, or the grid isn't ready yet --
# both treated as reachable so we fall back to a direct approach.
func _path_reaches(goal: Vector2) -> bool:
	if _path.is_empty():
		return true
	return _path[_path.size() - 1].distance_to(goal) <= REACHABLE_DIST

# Advances past reached waypoints and returns the next steering point, or the goal
# itself once the path is exhausted (final approach).
func _next_waypoint(goal: Vector2) -> Vector2:
	while _path_index < _path.size() and global_position.distance_to(_path[_path_index]) <= WAYPOINT_REACHED_DIST:
		_path_index += 1
	if _path_index < _path.size():
		return _path[_path_index]
	return goal

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
	var min_dist: float = INF
	for node in nodes:
		if node.is_depleted or _unreachable.has(node):
			continue
		var dist: float = global_position.distance_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			target_node = node
	# If everything was ruled unreachable, forget and retry -- the map may have
	# opened up (a building removed, or a closer resource depleted).
	if target_node == null and not _unreachable.is_empty():
		_unreachable.clear()
