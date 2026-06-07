extends CanvasLayer

@onready var wood_label: Label = $TopBar/WoodLabel
@onready var stone_label: Label = $TopBar/StoneLabel
@onready var gold_label: Label = $TopBar/GoldLabel
@onready var income_label: Label = $TopBar/IncomeLabel
@onready var build_placement: BuildPlacement = $"../../BuildPlacement"

@onready var build_barracks_button: Button = $Buttons/BuildBarracksBtn
@onready var build_woodhut_button: Button = $Buttons/BuildWoodhutBtn
@onready var recruit_woodsman_button: Button = $Buttons/RecruitWoodsmanBtn
@onready var recruit_miner_button: Button = $Buttons/RecruitMinerBtn
@onready var recruit_troop_button: Button = $Buttons/RecruitTroopBtn
@onready var restart_button: Button = $RestartBtn

@export var barracks_scene: PackedScene = load("res://scenes/buildings/barracks.tscn")
@export var woodhut_scene: PackedScene = load("res://scenes/buildings/woodhut.tscn")


func _ready() -> void:
	GameManager.resources_changed.connect(_update_display)
	GameManager.resources_changed.connect(_refresh_buttons)
	GameManager.selection_changed.connect(_refresh_buttons)

	recruit_woodsman_button.pressed.connect(_on_recruit_worker_btn_pressed.bind(true))
	recruit_miner_button.pressed.connect(_on_recruit_worker_btn_pressed.bind(false))
	build_woodhut_button.pressed.connect(_on_build_building_pressed.bind("woodhut"))
	build_barracks_button.pressed.connect(_on_build_building_pressed.bind("barracks"))
	recruit_troop_button.pressed.connect(_on_recruit_troop_pressed)
	restart_button.pressed.connect(_on_restart_btn_pressed)

	_update_display()
	_refresh_buttons()


func _update_display() -> void:
	wood_label.text = "Wood: %d" % GameManager.wood
	stone_label.text = "Stone: %d" % GameManager.stone
	gold_label.text = "Gold: %d" % int(GameManager.gold)
	income_label.text = "+%.1f/s" % GameManager.gold_income_rate

# Recruit buttons are only usable when the matching building is selected and the
# player can afford the unit.
func _refresh_buttons() -> void:
	var selected: Node = GameManager.selected_building
	if not is_instance_valid(selected):
		selected = null
	var barracks_selected: bool = selected is Barracks
	var woodhut_selected: bool = selected is Woodhut

	recruit_troop_button.disabled = not barracks_selected or GameManager.gold < GameManager.TROOP_COST
	recruit_woodsman_button.disabled = not woodhut_selected or GameManager.gold < GameManager.WORKER_COST
	recruit_miner_button.disabled = not woodhut_selected or GameManager.gold < GameManager.WORKER_COST
	build_barracks_button.disabled = not GameManager.can_pay(Barracks.COST)
	build_woodhut_button.disabled = not GameManager.can_pay(Woodhut.COST)

func _on_build_building_pressed(building: String) -> void:
	var scene: PackedScene = woodhut_scene if building == "woodhut" else barracks_scene
	var cost: Dictionary = Woodhut.COST if building == "woodhut" else Barracks.COST

	if not GameManager.can_pay(cost):
		return

	build_placement.begin_placement(scene, cost, true)

func _on_recruit_troop_pressed() -> void:
	var barracks: Barracks = GameManager.selected_building as Barracks
	if barracks == null or not barracks.can_queue():
		return
	# Charge only after confirming there's room to queue, so a troop is never free.
	if GameManager.recruit_troop():
		barracks.add_to_queue()


func _on_recruit_worker_btn_pressed(is_woodsman: bool) -> void:
	var woodhut: Woodhut = GameManager.selected_building as Woodhut
	if woodhut == null or not woodhut.can_queue():
		return
	if GameManager.recruit_worker():
		woodhut.add_to_queue(is_woodsman)

func _on_restart_btn_pressed() -> void:
	get_tree().paused = false
	GameManager.reset_values()
	get_tree().reload_current_scene()
