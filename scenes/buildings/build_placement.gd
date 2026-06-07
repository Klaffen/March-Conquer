extends Node2D
class_name BuildPlacement

@onready var buildings: Node2D = $"../World/Buildings"
@export var obstacle_mask: int = 1

var _active: bool = false
var _ghost: Node2D = null
var _building_scene: PackedScene = null
var _is_valid: bool = false
var _cost: Dictionary
var _owner_is_player: bool

signal placement_committed(building: Node2D)
signal placement_cancelled


func begin_placement(building_scene: PackedScene, cost: Dictionary, is_player: bool) -> void:
	if _active:
		cancel_placement()

	_active = true
	_building_scene = building_scene
	_cost = cost
	_owner_is_player = is_player

	_ghost = _building_scene.instantiate()
	_ghost.set("ghost", true)
	_ghost.name = "Ghost"

	var collision_shape: CollisionShape2D = _ghost.get_node("Hitbox/HitboxShape")
	collision_shape.disabled = true

	buildings.add_child(_ghost)

func cancel_placement() -> void:
	_reset_state()
	placement_cancelled.emit()

func _reset_state() -> void:
	if _ghost != null:
		_ghost.queue_free()

	_active = false
	_ghost = null
	_building_scene = null
	_is_valid = false


func _unhandled_input(_event: InputEvent) -> void:
	if (_active == false):
		return

	if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("right_click"):
		cancel_placement()
		return

	var pos: Vector2 = get_global_mouse_position()
	_ghost.global_position = pos

	_is_valid = is_footprint_clear(_ghost.get_node("Hitbox/HitboxShape"))

	if _is_valid and Input.is_action_just_pressed("left_click"):
		_try_commit()
		return

	_tint_ghost(_is_valid)

func is_footprint_clear(collision_shape: CollisionShape2D) -> bool:
	var physics_shape: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	physics_shape.collision_mask = obstacle_mask
	physics_shape.shape = collision_shape.shape
	physics_shape.transform = collision_shape.global_transform
	physics_shape.collide_with_areas = true

	var hits: Array[Dictionary] = get_world_2d().direct_space_state.intersect_shape(physics_shape, 32)
	for hit in hits:
		if not _ghost.is_ancestor_of(hit.collider):
			return false
	return true

func _try_commit() -> void:
	if not _is_valid:
		print("Can't commit, not valid placement")
		return

	if not GameManager.try_pay(_cost):
		print("Can't afford it")
		return

	_spawn_real(_ghost.global_position)

func _spawn_real(world_pos: Vector2) -> void:
	var building: Node2D = _building_scene.instantiate()
	building.global_position = world_pos
	buildings.add_child(building)

	placement_committed.emit(building)
	_reset_state()

func _tint_ghost(valid: bool) -> void:
	_ghost.modulate = GameManager.MODULATION_VALID if valid else GameManager.MODULATION_INVALID
