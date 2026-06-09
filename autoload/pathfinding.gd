extends Node

## Grid A* pathfinding over the terrain tilemap (autoload singleton).
##
## Units call find_path() to get world-space waypoints that route around static
## terrain (water/stone collision tiles) and building footprints. Call
## initialize() once with the active terrain TileMapLayer, and rebuild_obstacles()
## whenever a building is added or removed.

const OBSTACLE_GROUP: StringName = &"obstacles"
const TILE_PHYSICS_LAYER: int = 0
const MAX_FREE_CELL_SEARCH: int = 16
# Terrains units may never cross, even if a tile happens to lack a collision
# polygon. "path" is intentionally absent -- paths are walkable ground.
const BLOCKED_TERRAINS: Array[String] = ["water"]

var _astar: AStarGrid2D = null
var _tilemap: TileMapLayer = null
var _region: Rect2i = Rect2i()
# Cells that block movement independent of buildings (collision tiles, off-map).
var _static_solid: Dictionary = {}

func initialize(tilemap: TileMapLayer) -> void:
	_tilemap = tilemap
	_build_grid()

func is_ready() -> bool:
	return _astar != null

# Returns world-space waypoints from one point to another. Empty when no grid is
# built or start and goal share a cell -- callers should then move straight at
# the target.
func find_path(from_world: Vector2, to_world: Vector2) -> PackedVector2Array:
	if not is_ready():
		return PackedVector2Array()

	var from_cell: Vector2i = _nearest_free_cell(_clamp_cell(_world_to_cell(from_world)))
	var to_cell: Vector2i = _nearest_free_cell(_clamp_cell(_world_to_cell(to_world)))
	if from_cell == to_cell:
		return PackedVector2Array()

	var cell_path: Array[Vector2i] = _astar.get_id_path(from_cell, to_cell, true)
	var points: PackedVector2Array = PackedVector2Array()
	for cell in cell_path:
		points.append(_cell_to_world(cell))
	return points

# --- Debug accessors ---------------------------------------------------------

func get_region() -> Rect2i:
	return _region

func get_cell_size() -> Vector2:
	if _tilemap == null:
		return Vector2.ZERO
	return Vector2(_tilemap.tile_set.tile_size)

func is_cell_solid(cell: Vector2i) -> bool:
	return _astar != null and _region.has_point(cell) and _astar.is_point_solid(cell)

func cell_to_world(cell: Vector2i) -> Vector2:
	return _cell_to_world(cell)

# --- Grid construction -------------------------------------------------------

func _build_grid() -> void:
	if _tilemap == null:
		return
	_region = _tilemap.get_used_rect()
	if _region.size == Vector2i.ZERO:
		return

	_astar = AStarGrid2D.new()
	_astar.region = _region
	_astar.cell_size = Vector2(_tilemap.tile_set.tile_size)
	_astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_astar.update()

	_compute_static_solids()
	rebuild_obstacles()

# Caches tiles that block movement: physics-collision tiles (water/stone) and
# unpainted cells (off the playable area).
func _compute_static_solids() -> void:
	_static_solid.clear()
	var tile_set: TileSet = _tilemap.tile_set
	for y in range(_region.position.y, _region.end.y):
		for x in range(_region.position.x, _region.end.x):
			var cell: Vector2i = Vector2i(x, y)
			var data: TileData = _tilemap.get_cell_tile_data(cell)
			if data == null or data.get_collision_polygons_count(TILE_PHYSICS_LAYER) > 0:
				_static_solid[cell] = true
			elif data.terrain_set >= 0 and data.terrain >= 0 \
					and tile_set.get_terrain_name(data.terrain_set, data.terrain) in BLOCKED_TERRAINS:
				_static_solid[cell] = true

# Resets the grid to its static solidity, then stamps every building footprint.
# Call after a building is placed or removed.
func rebuild_obstacles() -> void:
	if not is_ready():
		return

	for y in range(_region.position.y, _region.end.y):
		for x in range(_region.position.x, _region.end.x):
			var cell: Vector2i = Vector2i(x, y)
			_astar.set_point_solid(cell, _static_solid.has(cell))

	for node in get_tree().get_nodes_in_group(OBSTACLE_GROUP):
		if node.get("ghost"):  # skip the translucent placement preview
			continue
		_stamp_footprint(node)

func _stamp_footprint(node: Node) -> void:
	var shape_node: CollisionShape2D = _footprint_shape(node)
	if shape_node == null:
		return
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	if rect == null:
		return

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

	var top_left: Vector2i = _world_to_cell(min_world)
	var bottom_right: Vector2i = _world_to_cell(max_world)
	for y in range(top_left.y, bottom_right.y + 1):
		for x in range(top_left.x, bottom_right.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			if _region.has_point(cell):
				_astar.set_point_solid(cell, true)

# --- Helpers -----------------------------------------------------------------

func _footprint_shape(node: Node) -> CollisionShape2D:
	var shape_node: CollisionShape2D = node.get_node_or_null("Solid/SolidShape")
	if shape_node == null:
		shape_node = node.get_node_or_null("Hitbox/HitboxShape")
	if shape_node == null:
		shape_node = _first_collision_shape(node)
	return shape_node

func _first_collision_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
		var found: CollisionShape2D = _first_collision_shape(child)
		if found != null:
			return found
	return null

func _world_to_cell(world: Vector2) -> Vector2i:
	return _tilemap.local_to_map(_tilemap.to_local(world))

func _cell_to_world(cell: Vector2i) -> Vector2:
	return _tilemap.to_global(_tilemap.map_to_local(cell))

func _clamp_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, _region.position.x, _region.end.x - 1),
		clampi(cell.y, _region.position.y, _region.end.y - 1)
	)

# Nearest non-solid cell via expanding ring search; returns the input if none found.
func _nearest_free_cell(cell: Vector2i) -> Vector2i:
	if not _astar.is_point_solid(cell):
		return cell
	for radius in range(1, MAX_FREE_CELL_SEARCH + 1):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if absi(dx) != radius and absi(dy) != radius:
					continue
				var candidate: Vector2i = Vector2i(cell.x + dx, cell.y + dy)
				if _region.has_point(candidate) and not _astar.is_point_solid(candidate):
					return candidate
	return cell
