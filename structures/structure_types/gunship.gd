## Structures that automatically attack nearby enemies
extends AttackStructure
class_name Gunship

var target_enemy: Enemy = null
@onready var attack_particles: GPUParticles2D = $gunship_attack_vfx

func update(delta: float) -> void:
	cooldown_timer -= delta
	_find_target()
	_track_target(delta)
	if target_enemy and position.distance_to(target_enemy.position) <= attack_range and cooldown_timer <= 0.0:
		attack()
		cooldown_timer = attack_cooldown

func _find_target():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = INF
	var closest_enemy = null
	for enemy in enemies:
		var dist = position.distance_to(enemy.position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = enemy
	target_enemy = closest_enemy

func _track_target(delta):
	if target_enemy:
		var to_enemy = target_enemy.position - position
		var desired_angle = to_enemy.angle()
		rotation = lerp_angle(rotation, desired_angle + PI/2, delta * 5.0) # offset because the sprite faces up and not right
	else:
		# smoothly rotate to default position
		rotation = lerp_angle(rotation, 0.0, delta * 5.0)

func attack() -> void:
	if target_enemy and position.distance_to(target_enemy.position) <= attack_range:
		if target_enemy.has_method("take_damage"):
			attack_particles.emitting = true
			target_enemy.take_damage(damage)

func take_damage(amount: float) -> void:
	health -= amount
	print("New health: " + str(health))
	if health <= 0:
		var particle = death_particles.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		get_tree().current_scene.add_child(particle)
		var parent = get_parent()
		print(parent)
		if parent and parent.has_method("remove_structure"):
			parent.remove_structure(self)
