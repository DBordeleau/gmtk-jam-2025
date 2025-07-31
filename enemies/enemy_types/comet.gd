extends Asteroid

func _physics_process(delta: float) -> void:
	move_enemy(delta)
	_rotate_to_direction()
	_check_collisions()

func _rotate_to_direction():
	if velocity.length() > 0:
		rotation = velocity.angle()
