extends CharacterBody2D
class_name Troop

const SPEED: float = 40.0
const DAMAGE: int = 10
const ATTACK_RANGE: float = 20.0
const ATTACK_INTERVAL: float = 1.0

const FRIENDLY_COLOR: Color = Color("004900")
const ENEMY_COLOR: Color = Color("a10000")

@export var max_hp: int = 30
@export var is_player_troop: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $HPBar


var hp: int
var attack_timer: float = 0.0
var target: Node = null

func _ready() -> void:
	hp = max_hp
	hp_bar.modulate = FRIENDLY_COLOR if is_player_troop else ENEMY_COLOR
	hp_bar.max_value = max_hp
	add_to_group("player_troops" if is_player_troop else "enemy_troops")

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_find_target()
	if target == null:
		_play_animation("idle", false)
		return

	# Walk toward the closest point on the target's hitbox, not its center,
	# so we stop at a building's wall instead of walking into it.
	var aim_point: Vector2 = _aim_point()
	var to_aim: Vector2 = aim_point - global_position
	var facing: Vector2 = target.global_position - global_position
	if to_aim.length() <= ATTACK_RANGE:
		attack_timer += delta
		if attack_timer >= ATTACK_INTERVAL:
			attack_timer = 0.0
			_play_attack_animation(facing)
			_attack()
	else:
		velocity = to_aim.normalized() * SPEED
		_play_walk_animation(facing)
		move_and_slide()

func _find_target() -> void:
	var enemy_group: String = "enemy_troops" if is_player_troop else "player_troops"
	target = _nearest_in_group(enemy_group)
	if target == null:
		var castle_group: String = "enemy_castle" if is_player_troop else "player_castle"
		target = _nearest_in_group(castle_group)

func _nearest_in_group(group: String) -> Node:
	var nearest: Node = null
	var min_dist: float = INF
	for node in get_tree().get_nodes_in_group(group):
		var dist: float = global_position.distance_to(node.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest = node
	return nearest

# Closest point on the target's hitbox to this troop. Falls back to the
# target's center for shapes we don't special-case (e.g. troop capsules).
func _aim_point() -> Vector2:
	var shape_node: CollisionShape2D = _find_collision_shape(target)
	if shape_node != null and shape_node.shape is RectangleShape2D:
		var half: Vector2 = (shape_node.shape as RectangleShape2D).size * 0.5 * shape_node.global_scale
		var center: Vector2 = shape_node.global_position
		return Vector2(
			clampf(global_position.x, center.x - half.x, center.x + half.x),
			clampf(global_position.y, center.y - half.y, center.y + half.y)
		)
	return target.global_position

func _find_collision_shape(node: Node) -> CollisionShape2D:
	for child in node.get_children():
		if child is CollisionShape2D:
			return child
		var found: CollisionShape2D = _find_collision_shape(child)
		if found != null:
			return found
	return null

func _attack() -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	hp -= amount
	hp_bar.value = hp
	print(hp_bar.value)
	if hp <= 0:
		queue_free()

func _play_walk_animation(direction: Vector2) -> void:
	_play_animation("walk", direction.x < 0)

func _play_attack_animation(direction: Vector2) -> void:
	_play_animation("attack", direction.x < 0)

func _play_animation(anim_name: StringName, flip: bool) -> void:
	sprite.flip_h = flip
	if sprite.animation != anim_name:
		sprite.play(anim_name)
