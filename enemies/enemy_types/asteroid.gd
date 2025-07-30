## Controls behaviour of Asteroids.
extends Enemy

@export var target_position: Vector2 = Vector2.ZERO
var has_collided: bool = false # prevents double damage

@export var death_particles: PackedScene

# Set the target to the center of the screen
func _ready():
	var viewport = get_viewport()
	target_position = viewport.get_visible_rect().size / 2
	super._ready()

func _physics_process(delta: float) -> void:
	move_enemy(delta)
	_check_collisions()

func move_enemy(delta: float) -> void:
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _check_collisions():
	if has_collided:
		return
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider and collider.has_method("take_damage"):
			print("Asteroid dealing", damage, "damage to", collider)
			collider.take_damage(damage)
			has_collided = true
			die()
			break

func die():
	# play particle fx
	var particle = death_particles.instantiate()
	particle.position = global_position
	particle.rotation = global_rotation
	particle.emitting = true
	get_tree().current_scene.add_child(particle)
	super.die()
