extends Camera2D

const SPEED: float = 200.0

func _process(delta: float) -> void:
	var direction := Vector2.ZERO
	if Input.is_action_pressed("camera_up"):
		direction.y -= 1
	if Input.is_action_pressed("camera_down"):
		direction.y += 1
	if Input.is_action_pressed("camera_left"):
		direction.x -= 1
	if Input.is_action_pressed("camera_right"):
		direction.x += 1
	position += direction.normalized() * SPEED * delta
