extends Node

var wood: int
var stone: int
var gold: float
var gold_income_rate: float
var troop_count: int

enum WorkerTypes {WOODSMAN, MINER}

const WORKER_COST: int = 10
const TROOP_COST: int = 5
const GOLD_PER_TROOP: float = 0.5
const MODULATION_INVALID: Color = Color("ff000078")
const MODULATION_VALID: Color = Color("00f70078")


signal resources_changed
signal game_over(player_won: bool)

func _ready() -> void:
	reset_values()

func reset_values() -> void:
	wood = 10
	stone = 10
	gold = 10.0
	gold_income_rate = 1.0
	troop_count = 0

func on_income_tick() -> void:
	gold += gold_income_rate
	resources_changed.emit()

func add_wood(amount: int) -> void:
	wood += amount
	resources_changed.emit()

func add_stone(amount: int) -> void:
	stone += amount
	resources_changed.emit()

func can_pay(cost: Dictionary) -> bool:
	return wood >= cost.wood and stone >= cost.stone

func recruit_worker() -> bool:
	if gold >= WORKER_COST:
		gold -= WORKER_COST
		resources_changed.emit()
		return true
	return false

func try_pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false

	wood -= cost.wood
	stone -= cost.stone
	resources_changed.emit()

	return true

func recruit_troop() -> bool:
	if gold >= TROOP_COST:
		gold -= TROOP_COST
		troop_count += 1
		resources_changed.emit()
		return true
	return false

func end_game(player_won: bool) -> void:
	game_over.emit(player_won)
