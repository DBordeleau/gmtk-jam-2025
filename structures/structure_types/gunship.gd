## Structures that automatically attack nearby enemies
extends AttackStructure
class_name Gunship

var target_enemy: Enemy = null

@onready var attack_particles: GPUParticles2D = $gunship_attack_vfx
@onready var attack_sfx: AudioStreamPlayer = $AttackSFX
@onready var death_sfx: AudioStreamPlayer = $DeathSFX


func _init():
	damage = 10
	attack_range = 150
	attack_cooldown = 1.0
	health = 10
	speed = 0.6
	tooltip_desc = "A spaceship equipped with a powerful cannon. Orbits your home world, blasting the nearest threat within " + str(attack_range) + " range for " + str(damage) + " damage every " + str(attack_cooldown) + " seconds. Dies on impact with any asteroid."

	super._init()


func update(delta: float) -> void:
	cooldown_timer -= delta
	_find_target()
	_track_target(delta)
	if target_enemy and position.distance_to(target_enemy.position) <= attack_range and cooldown_timer <= 0.0:
		attack()
		cooldown_timer = attack_cooldown


func _find_target():
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	var closest_dist         = INF
	var closest_enemy        = null
	for enemy in enemies:
		var dist: float = position.distance_to(enemy.position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = enemy
	target_enemy = closest_enemy


func _track_target(delta):
	if target_enemy:
		var to_enemy: Vector2    = target_enemy.position - position
		var desired_angle: float = to_enemy.angle()
		rotation = lerp_angle(rotation, desired_angle + PI/2, delta * 5.0) # offset because the sprite faces up and not right
	else:
		# smoothly rotate to default position
		rotation = lerp_angle(rotation, 0.0, delta * 5.0)


func attack() -> void:
	if target_enemy and position.distance_to(target_enemy.position) <= attack_range:
		if target_enemy.has_method("take_damage"):
			attack_particles.emitting = true
			attack_sfx.play()
			target_enemy.take_damage(damage)


func take_damage(amount: float) -> void:
	# Check if this is an orbital structure and if shield is active
	if is_orbital and is_shielded:
		print("Gunship damage blocked by shield!")
		return
		
	health -= amount
	print("New health: " + str(health))
	if health <= 0:
		var particle: Node   = death_particles.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		var camera: Camera2D = get_viewport().get_camera_2d()
		if camera and camera.has_method("shake"):
			camera.shake(12.0, 0.5)
		if death_sfx:
			# Detach the audio player so it can finish playing
			death_sfx.get_parent().remove_child(death_sfx)
			get_tree().current_scene.add_child(death_sfx)
			death_sfx.play()
			# Optionally, queue_free the audio player after it finishes
			death_sfx.finished.connect(func(): death_sfx.queue_free())
		get_tree().current_scene.add_child(particle)
		var parent: Node = get_parent()
		print(parent)
		if parent and parent.has_method("remove_structure"):
			parent.remove_structure(self)


# used by game_manager to warm up attack effects
func shoot():
	if attack_particles:
		attack_particles.emitting = true
	if attack_sfx:
		attack_sfx.play()


func update_tooltip_desc():
	tooltip_desc = "A spaceship equipped with a powerful cannon. Orbits your home world, blasting the nearest threat within " + str(attack_range) + " range for " + str(damage) + " damage every " + str(attack_cooldown) + " seconds. Dies on impact with any asteroid."
