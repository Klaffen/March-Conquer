extends Node2D
class_name Building

# Shared behaviour for selectable, producing buildings (barracks, woodhut, ...).
# Selection STATE lives in GameManager; this handles click-to-select, the
# selected outline, and the production-queue plumbing. Subclasses define WHAT
# they produce (add_to_queue) and may override _on_unit_spawned() for any extra
# behaviour when a finished unit appears.

@export var outline: Shader = load("res://shaders/outline.gdshader")

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var build_queue: Node = get_node_or_null("BuildQueue")

var selected: bool = false

# Subclasses that override _ready() must call super._ready() so this still runs.
func _ready() -> void:
	hitbox.input_event.connect(_on_hitbox_input_event)
	set_selected(false)  # start without an outline, ignoring whatever the scene ships

	if build_queue != null:
		build_queue.finished_item.connect(_spawn_unit)

# --- Selection ---------------------------------------------------------------

func _on_hitbox_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("left_click"):
		GameManager.select_building(self)
		# Mark handled so selector.gd (which deselects on empty clicks) doesn't
		# immediately clear this selection.
		get_viewport().set_input_as_handled()

func set_selected(value: bool) -> void:
	selected = value
	if value:
		if sprite_2d.material == null:
			sprite_2d.material = ShaderMaterial.new()
		sprite_2d.material.shader = outline
	else:
		sprite_2d.material = null

# --- Production --------------------------------------------------------------

func can_queue() -> bool:
	return build_queue != null and not build_queue.is_full()

# Spawns the finished unit at the spawn point and parents it under the world entities.
# Override _on_unit_spawned() for building-specific follow-up (animation, income).
func _spawn_unit(unit_scene: PackedScene) -> void:
	if unit_scene == null:
		return

	var unit: Node2D = unit_scene.instantiate()
	var spawn: Node2D = get_node_or_null("SpawnPoint")
	unit.global_position = spawn.global_position if spawn != null else global_position
	get_tree().root.get_node("MainGame/World/Entities").add_child(unit)

	_on_unit_spawned(unit)

func _on_unit_spawned(_unit: Node2D) -> void:
	pass
