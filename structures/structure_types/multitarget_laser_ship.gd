class_name LaserShip
extends AttackStructure

@export var laser_color := Color.RED
@export var laser_width := 4.0
@export var start_distance := 20.0
## How long lasers take to appear/disappear
@export var laser_grow_time := 0.1
## How long lasers stay visible during attack
@export var laser_duration := 0.3

var enemies_in_range: Array[Node2D] = []
# Track if the ship is ready to fire (cooldown expired)
var ready_to_fire: bool           = true
var cleanup_timer: SceneTreeTimer = null
# New variables for delayed firing
var target_acquisition_delay: float = 0.3
var acquisition_timer: float = 0.0
var is_acquiring_targets: bool = false

@onready var range_area: Area2D = $Range
@onready var laser_system: LaserSystem = $LaserSystem
@onready var smoke_vfx: GPUParticles2D = $SmokeVFX
@onready var attack_sfx: AudioStreamPlayer = $AttackSFX
@onready var death_sfx: AudioStreamPlayer = $DeathSFX

var max_health: int = 20


func _init():
	damage = 10
	attack_range = 215
	attack_cooldown = 3.0
	speed = 0.6  # Add this line
	tooltip_desc = "A resilient ship that fires laser beams at all enemies within " + str(attack_range) + " range every " + str(attack_cooldown) + " seconds. Can survive 1 collision with an asteroid."
	super._init()


func _ready() -> void:
	super._ready()

	# Connect area signals for enemy detection
	if range_area:
		print("LaserShip: Connecting Range signals")
		range_area.body_entered.connect(_on_enemy_entered)
		range_area.body_exited.connect(_on_enemy_exited)
		print("LaserShip: Range signals connected successfully")
	else:
		print("LaserShip ERROR: No range_area found!")

	# Configure laser system
	if laser_system:
		laser_system.color = laser_color
		laser_system.line_width = laser_width
		laser_system.start_distance = start_distance
		laser_system.growth_time = laser_grow_time

	# Start ready to fire
	ready_to_fire = true


func _process(delta: float) -> void:
	# Don't call super._process() to avoid double cooldown decrementing
	# Just handle the drawing queue manually
	queue_redraw()

	# Handle target acquisition delay
	if is_acquiring_targets:
		acquisition_timer -= delta
		if acquisition_timer <= 0.0:
			is_acquiring_targets = false
			# Fire at all targets we've acquired, but only if we're still ready to fire
			if not enemies_in_range.is_empty() and ready_to_fire:
				fire_at_all_targets()

	# Only update cooldown timer if we're actually on cooldown
	if not ready_to_fire:
		cooldown_timer -= delta
		# Remove excessive debug output, only print occasionally
		var time_remaining = fmod(cooldown_timer, 0.5)
		if time_remaining > 0.45 or cooldown_timer <= 0.1:
			print("LaserShip cooldown remaining: ", cooldown_timer)
		if cooldown_timer <= 0.0:
			ready_to_fire = true
			print("LaserShip ready to fire again - enemies in range: ", enemies_in_range.size())

			# When cooldown expires, if we have enemies and aren't already acquiring, start acquisition
			if not enemies_in_range.is_empty() and not is_acquiring_targets:
				print("LaserShip: Starting acquisition after cooldown expired")
				start_target_acquisition()
			elif enemies_in_range.is_empty():
				print("LaserShip: No enemies to attack after cooldown expired")
			elif is_acquiring_targets:
				print("LaserShip: Already acquiring targets when cooldown expired")


func _on_enemy_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)
		print("LaserShip: Enemy entered range. Ready to fire: ", ready_to_fire, " Acquiring: ", is_acquiring_targets, " Shield: ", is_shielded, " Enemies in range: ", enemies_in_range.size())

		# If ready to fire and not already acquiring targets
		if ready_to_fire and not is_acquiring_targets:
			# If this is the first enemy, start target acquisition delay
			if enemies_in_range.size() == 1:
				start_target_acquisition()
			# If we already have multiple enemies and aren't acquiring, fire immediately
			elif enemies_in_range.size() > 1:
				fire_at_all_targets()
		# If we're ready to fire and already acquiring, but now have multiple enemies, fire immediately
		elif ready_to_fire and is_acquiring_targets and enemies_in_range.size() > 1:
			print("LaserShip: Multiple enemies detected during acquisition - firing immediately")
			fire_at_all_targets()
		else:
			print("LaserShip: Enemy entered but can't attack yet - ready_to_fire: ", ready_to_fire, " is_acquiring: ", is_acquiring_targets)


func _on_enemy_exited(body: Node2D) -> void:
	if body in enemies_in_range:
		enemies_in_range.erase(body)
		print("LaserShip: Enemy exited range. Enemies remaining: ", enemies_in_range.size(), " Shield: ", is_shielded)
		
		# If no enemies left, cancel target acquisition
		if enemies_in_range.is_empty():
			is_acquiring_targets = false
			acquisition_timer = 0.0


func start_target_acquisition() -> void:
	if not ready_to_fire:
		return
		
	print("LaserShip starting target acquisition for ", target_acquisition_delay, " seconds")
	is_acquiring_targets = true
	acquisition_timer = target_acquisition_delay



func fire_at_all_targets() -> void:
	if not ready_to_fire:
		return
	if enemies_in_range.is_empty() or not laser_system:
		return

	# Cancel target acquisition if we're firing
	is_acquiring_targets = false
	acquisition_timer = 0.0

	print("LaserShip firing at ", enemies_in_range.size(), " enemies (Time: ", Time.get_time_dict_from_system(), ")")

	# Use LaserSystem to create lasers with particles
	laser_system.target_enemies(enemies_in_range)

	attack_sfx.play()

	# Deal damage to all enemies
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			deal_damage_to_enemy(enemy)

	# Put the weapon on cooldown AFTER firing
	ready_to_fire = false
	cooldown_timer = attack_cooldown
	print("LaserShip on cooldown for ", attack_cooldown, " seconds (until Time: ", Time.get_time_dict_from_system()["second"] + attack_cooldown, ")")

	# Cancel any existing cleanup timer
	if cleanup_timer:
		cleanup_timer = null

	# Schedule laser cleanup after laser_duration - store the timer reference
	cleanup_timer = get_tree().create_timer(laser_duration)
	cleanup_timer.timeout.connect(_safe_cleanup_all_lasers)


func _safe_cleanup_all_lasers() -> void:
	# Only cleanup if we're still valid and in the tree
	if is_inside_tree() and not is_queued_for_deletion():
		cleanup_all_lasers()
	cleanup_timer = null


func cleanup_all_lasers() -> void:
	# Cancel any pending cleanup timer
	if cleanup_timer:
		cleanup_timer = null

	if laser_system and is_instance_valid(laser_system):
		# Remove all lasers regardless of firing state
		laser_system.target_enemies([])


func deal_damage_to_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		print("Dealt ", damage, " damage to ", enemy.name)


# Override the base attack method - we handle our own timing now
func attack() -> void:
	pass


func take_damage(amount: float) -> void:
	# Check if this is an orbital structure and if shield is active
	if is_orbital and is_shielded:
		print("LaserShip damage blocked by shield!")
		return
		
	health -= 10 # Laser ship always takes 10 damage, so it can survive a collision even with a big asteroid
	print("New health: " + str(health))
	if health < max_health:
		smoke_vfx.emitting = true
	if health <= 0:
		var particle: Node = death_particles.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		get_tree().current_scene.add_child(particle)
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
		var parent: Node = get_parent()
		print(parent)
		if parent and parent.has_method("remove_structure"):
			parent.remove_structure(self)


# Clean up when destroyed
func _exit_tree() -> void:
	cleanup_all_lasers()


func update_tooltip_desc():
	tooltip_desc = "A resilient ship that fires laser beams at all enemies within " + str(attack_range) + " range every " + str(attack_cooldown) + " seconds. Can survive 1 collision with an asteroid. Cost +10"
