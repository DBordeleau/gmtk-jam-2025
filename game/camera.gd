## literally just a camera shake
extends Camera2D

var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO

func shake(amount: float = 8.0, duration: float = 0.3):
	shake_amount = amount
	shake_duration = duration
	shake_timer = duration

func _process(delta):
	if shake_timer > 0.0:
		shake_timer -= delta
		var t = shake_timer / shake_duration
		var current_amount = shake_amount * t * t * t * 2.0
		shake_offset = Vector2(
			randf_range(-1, 1),
			randf_range(-1, 1)
		) * current_amount
		offset = shake_offset
	else:
		offset = Vector2.ZERO
