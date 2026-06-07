extends Timer

func _ready() -> void:
	timeout.connect(_on_timeout)

func _on_timeout() -> void:
	GameManager.on_income_tick()
