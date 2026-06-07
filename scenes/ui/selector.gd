extends Node

func _ready() -> void:
	# Area2D mouse signals (input_event / mouse_entered / mouse_exited) only fire
	# when the viewport has physics object picking enabled.
	get_viewport().physics_object_picking = true

func _unhandled_input(event: InputEvent) -> void:
	# Buildings consume their own left-click (set_input_as_handled), so anything
	# reaching here is a click on empty space (or a deselect key) — clear it.
	if event.is_action_pressed("left_click") \
	or event.is_action_pressed("right_click") \
	or event.is_action_pressed("escape"):
		GameManager.select_building(null)
