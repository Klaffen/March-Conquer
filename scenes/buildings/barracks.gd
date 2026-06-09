extends Building
class_name Barracks

# These never vary per instance, so they are preloaded consts rather than @export
# vars. An @export PackedScene with a load() default gets serialised as null when
# the script is attached to an instanced building in the editor, which crashes
# recruitment; a const has no inspector field to null out.
const TROOP_SCENE: PackedScene = preload("res://scenes/units/troop.tscn")
const BUILD_ITEM_SCENE: PackedScene = preload("res://scenes/buildings/build_item.tscn")
@export var ghost: bool = false

@export var knight_icon: CompressedTexture2D = load("res://assets/sprites/npcs/knight_icon.png")

const COST: Dictionary = {"wood": 10, "stone": 5}

enum State { IDLE, JUST_PRODUCED_IDLE, PRODUCING, JUST_PRODUCED_PRODUCING }

const CELL_W: float = 112.0
# The barracks art is inset within each 112x144 cell (transparent padding around
# it). Every state frame is cropped to the same inset rect so the sprite keeps a
# constant size and position when the region swaps between production states --
# otherwise the centered sprite visibly grows/shifts the first time it produces.
const CROP_X: float = 14.0
const CROP_Y: float = 4.0
const CROP_W: float = 84.0
const CROP_H: float = 127.0
const REGIONS: Array[Rect2] = [
	Rect2(CROP_X + CELL_W * 0, CROP_Y, CROP_W, CROP_H),  # just produced, now idle
	Rect2(CROP_X + CELL_W * 1, CROP_Y, CROP_W, CROP_H),  # idle
	Rect2(CROP_X + CELL_W * 2, CROP_Y, CROP_W, CROP_H),  # just produced, still producing
	Rect2(CROP_X + CELL_W * 3, CROP_Y, CROP_W, CROP_H),  # still producing
]

const JUST_PRODUCED_DURATION: float = 1.0

const income: float = 0.25

var state: State = State.IDLE
var _just_produced_timer: float = 0.0

func _ready() -> void:
	super._ready()
	# Own the sprite region so the resting look matches the idle production frame
	# from the start; the scene's region_rect is then only an editor preview.
	sprite_2d.region_enabled = true
	sprite_2d.region_rect = REGIONS[1]  # idle

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
func add_to_queue(unit_scene: PackedScene = null, icon: Texture2D = null, time: float = 5.0) -> void:
	if unit_scene == null:
		unit_scene = TROOP_SCENE
	if icon == null:
		icon = knight_icon

	var build_item: BuildItem = BUILD_ITEM_SCENE.instantiate()
	build_item.initialize(unit_scene, icon, time)

	if not build_queue.add(build_item):
		build_item.queue_free()
		return

	_update_state()

func _on_unit_spawned(_unit: Node2D) -> void:
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
		State.JUST_PRODUCED_IDLE:       sprite_2d.region_rect = REGIONS[0]
		State.IDLE:                     sprite_2d.region_rect = REGIONS[1]
		State.JUST_PRODUCED_PRODUCING:  sprite_2d.region_rect = REGIONS[2]
		State.PRODUCING:                sprite_2d.region_rect = REGIONS[3]
