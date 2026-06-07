extends Node2D
class_name BuildItem

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var timer: Timer = $Timer

var initialized: bool = false
var build_time: float = 5.0
var unit_scene: PackedScene
var _texture: Texture2D

signal finished(unit_scene: PackedScene)

func _ready() -> void:
	timer.timeout.connect(_build_finished)
	if initialized:
		_apply()

func _process(_delta: float) -> void:
	if not initialized:
		return

	progress_bar.value = timer.time_left

func _build_finished() -> void:
	finished.emit(unit_scene)

# Safe to call before or after the item enters the tree. Visuals are applied
# in _ready() if the node is not ready yet.
func initialize(unit: PackedScene, texture: Texture2D, time: float = 5.0) -> void:
	unit_scene = unit
	_texture = texture
	build_time = time
	initialized = true
	if is_node_ready():
		_apply()

func _apply() -> void:
	sprite_2d.texture = _texture
	progress_bar.max_value = build_time

func start() -> void:
	timer.start(build_time)
