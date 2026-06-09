extends Node2D

## Debug overlay for grid pathfinding. Press F1 to toggle.
## Draws solid pathfinding cells (red) and every troop's active path (green).

const SOLID_COLOR: Color = Color(1.0, 0.0, 0.0, 0.22)
const PATH_COLOR: Color = Color(0.1, 1.0, 0.2, 0.85)
const PATH_WIDTH: float = 1.5
const TOGGLE_KEY: Key = KEY_F1

var _enabled: bool = false

func _ready() -> void:
	z_index = 1000  # draw above buildings and units

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == TOGGLE_KEY:
		_enabled = not _enabled
		queue_redraw()

func _process(_delta: float) -> void:
	if _enabled:
		queue_redraw()  # paths move every frame

func _draw() -> void:
	if not _enabled or not Pathfinding.is_ready():
		return

	var region: Rect2i = Pathfinding.get_region()
	var size: Vector2 = Pathfinding.get_cell_size()
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var cell: Vector2i = Vector2i(x, y)
			if Pathfinding.is_cell_solid(cell):
				var top_left: Vector2 = to_local(Pathfinding.cell_to_world(cell)) - size * 0.5
				draw_rect(Rect2(top_left, size), SOLID_COLOR)

	for unit in get_tree().get_nodes_in_group("player_troops"):
		_draw_unit_path(unit)
	for unit in get_tree().get_nodes_in_group("enemy_troops"):
		_draw_unit_path(unit)
	for unit in get_tree().get_nodes_in_group("workers"):
		_draw_unit_path(unit)

func _draw_unit_path(unit: Node) -> void:
	var path_value: Variant = unit.get("_path")
	if not (path_value is PackedVector2Array):
		return
	var path: PackedVector2Array = path_value
	if path.size() < 2:
		return
	var local_points: PackedVector2Array = PackedVector2Array()
	for point in path:
		local_points.append(to_local(point))
	draw_polyline(local_points, PATH_COLOR, PATH_WIDTH)
