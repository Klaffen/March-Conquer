extends Node

@export var entities: Node2D

var troop_scene: PackedScene = load("res://scenes/units/troop.tscn")

func _ready() -> void:
	# Build the pathfinding grid from the terrain, and re-stamp building
	# footprints whenever the player places a new building.
	var tilemap: TileMapLayer = get_node_or_null("World/level/Tilemap")
	if tilemap != null:
		Pathfinding.initialize(tilemap)

	var placement: Node = get_node_or_null("BuildPlacement")
	if placement != null:
		placement.placement_committed.connect(_on_building_placed)

	# Debug overlay for the pathfinding grid (toggle with F1).
	var debug: Node2D = preload("res://scenes/debug/pathfinding_debug.gd").new()
	debug.name = "PathfindingDebug"
	$World.add_child(debug)

func _on_building_placed(_building: Node2D) -> void:
	Pathfinding.rebuild_obstacles()

# Enemy troop production (the player recruits via the selected building's queue).
func spawn_troop(player: bool) -> bool:
	if player:
		return false

	var portal: Node = get_node_or_null("World/level/Portal")
	if portal == null:
		return false

	var troop: Troop = troop_scene.instantiate()
	troop.global_position = portal.global_position
	troop.is_player_troop = false
	entities.add_child(troop)
	return true
