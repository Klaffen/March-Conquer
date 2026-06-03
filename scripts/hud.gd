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

@export var barracks_scene: PackedScene = load("res://scenes/barracks.tscn")
@export var woodhut_scene: PackedScene = load("res://scenes/woodhut.tscn")

func _ready() -> void:
	GameManager.resources_changed.connect(_update_display)

	_on_resource_change()
	GameManager.resources_changed.connect(_on_resource_change)

func _update_display() -> void:
	wood_label.text = "Wood: %d" % GameManager.wood
	stone_label.text = "Stone: %d" % GameManager.stone
	gold_label.text = "Gold: %d" % int(GameManager.gold)
	income_label.text = "+%.1f/s" % GameManager.gold_income_rate


func _on_resource_change() -> void:
	recruit_woodsman_button.disabled = GameManager.gold < 10
	recruit_miner_button.disabled = GameManager.gold < 10
	build_barracks_button.disabled = not GameManager.can_pay(Barracks.COST)
	build_woodhut_button.disabled = not GameManager.can_pay(Woodhut.COST)

func _on_build_building_pressed(building: String) -> void:
	var scene := woodhut_scene if building == "woodhut" else barracks_scene
	var cost := Woodhut.COST if building == "woodhut" else Barracks.COST

	if not GameManager.can_pay(cost):
		return

	build_placement.begin_placement(scene, cost, true)

func _on_recruit_troop_pressed() -> void:
	if GameManager.recruit_troop():
		get_tree().root.get_node("MainGame").spawn_troop()


func _on_recruit_worker_btn_pressed(is_woodsman: bool) -> void:
	if GameManager.recruit_worker():
		get_tree().root.get_node("MainGame").spawn_worker(true, is_woodsman)
