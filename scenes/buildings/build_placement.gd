extends Node2D
class_name BuildPlacement

@onready var buildings: Node2D = $"../World/Buildings"
@onready var terrain_layer: TileMapLayer = get_node_or_null("../World/level/Tilemap")
@export var obstacle_mask: int = 1
# Building is disallowed on any cell whose terrain has one of these names.
@export var blocked_terrains: Array[String] = ["path", "water"]

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

	# The ghost carries the same Solid body as the real building; disable it so it
	# doesn't physically block troops while the player is still positioning it.
	var solid_shape: CollisionShape2D = _ghost.get_node_or_null("Solid/SolidShape")
	if solid_shape != null:
		solid_shape.disabled = true

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

	var footprint: CollisionShape2D = _ghost.get_node("Hitbox/HitboxShape")
	_is_valid = is_footprint_clear(footprint) and not _footprint_on_blocked_terrain(footprint)

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

# True if any tile under the footprint belongs to a forbidden terrain (path/water).
# Reads the tilemap directly so it never affects physics or troop movement.
func _footprint_on_blocked_terrain(shape_node: CollisionShape2D) -> bool:
	if terrain_layer == null:
		return false
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect == null:
		return false

	# World-space AABB of the footprint (handles building rotation/scale).
	var xf: Transform2D = shape_node.global_transform
	var half: Vector2 = rect.size * 0.5
	var corners: Array[Vector2] = [
		xf * Vector2(-half.x, -half.y),
		xf * Vector2(half.x, -half.y),
		xf * Vector2(half.x, half.y),
		xf * Vector2(-half.x, half.y),
	]
	var min_world: Vector2 = corners[0]
	var max_world: Vector2 = corners[0]
	for corner in corners:
		min_world = min_world.min(corner)
		max_world = max_world.max(corner)

	var top_left: Vector2i = terrain_layer.local_to_map(terrain_layer.to_local(min_world))
	var bottom_right: Vector2i = terrain_layer.local_to_map(terrain_layer.to_local(max_world))

	var tile_set: TileSet = terrain_layer.tile_set
	for cell_y in range(top_left.y, bottom_right.y + 1):
		for cell_x in range(top_left.x, bottom_right.x + 1):
			var data: TileData = terrain_layer.get_cell_tile_data(Vector2i(cell_x, cell_y))
			if data == null:
				continue
			if data.terrain_set < 0 or data.terrain < 0:
				continue
			if tile_set.get_terrain_name(data.terrain_set, data.terrain) in blocked_terrains:
				return true
	return false

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
