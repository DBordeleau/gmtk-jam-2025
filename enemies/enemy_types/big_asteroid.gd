## Controls behaviour of Asteroids.
extends Asteroid
class_name BigAsteroid

@export var damage_particles: PackedScene


func take_damage(amount: int):
	if health - amount > 0:
		var particle: Node = damage_particles.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		get_tree().current_scene.add_child(particle)
		sprite.scale = Vector2(1, 1)
		collider.scale = Vector2(2.3, 2.3)
		damage = damage / 2
		base_speed = 50  # Update base_speed instead of speed to preserve multipliers
	super.take_damage(amount)
