extends CharacterBody2D

const SPEED: float = 40.0
const DAMAGE: int = 10
const ATTACK_RANGE: float = 20.0
const ATTACK_INTERVAL: float = 1.0

@export var max_hp: int = 30
@export var is_player_troop: bool = true

var hp: int
var attack_timer: float = 0.0
var target: Node = null

func _ready() -> void:
	hp = max_hp
	add_to_group("player_troops" if is_player_troop else "enemy_troops")

func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		_find_target()
	if target == null:
		return

	var direction = target.global_position - global_position
	if direction.length() <= ATTACK_RANGE:
		attack_timer += delta
		if attack_timer >= ATTACK_INTERVAL:
			attack_timer = 0.0
			_attack()
	else:
		velocity = direction.normalized() * SPEED
		move_and_slide()

func _find_target() -> void:
	var enemy_group = "enemy_troops" if is_player_troop else "player_troops"
	var enemies = get_tree().get_nodes_in_group(enemy_group)
	if enemies.is_empty():
		var castle_group = "enemy_castle" if is_player_troop else "player_castle"
		var castles = get_tree().get_nodes_in_group(castle_group)
		target = castles[0] if not castles.is_empty() else null
	else:
		target = enemies[0]

func _attack() -> void:
	if target != null and target.has_method("take_damage"):
		target.take_damage(DAMAGE)

func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()
