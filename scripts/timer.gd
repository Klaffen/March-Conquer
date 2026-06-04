extends Timer

func _on_timeout() -> void:
	GameManager.on_income_tick()
