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
var ready_to_fire: bool = true

@onready var range_area: Area2D = $Range
@onready var laser_system: LaserSystem = $LaserSystem

@onready var attack_sfx: AudioStreamPlayer = $AttackSFX
@onready var death_sfx: AudioStreamPlayer = $DeathSFX

func _ready() -> void:
	super._ready()
	
	# Connect area signals for enemy detection
	if range_area:
		range_area.body_entered.connect(_on_enemy_entered)
		range_area.body_exited.connect(_on_enemy_exited)
	
	# Configure laser system
	if laser_system:
		laser_system.color = laser_color
		laser_system.line_width = laser_width
		laser_system.start_distance = start_distance
		laser_system.growth_time = laser_grow_time
	
	# Start ready to fire
	ready_to_fire = true

func _process(delta: float) -> void:
	super._process(delta)
	
	# Only update cooldown timer if we're actually on cooldown
	if not ready_to_fire:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			ready_to_fire = true
			print("LaserShip ready to fire again")
			
			# Check if we have enemies to attack now that we're ready
			if not enemies_in_range.is_empty():
				fire_at_all_targets()

func _on_enemy_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)
		print("Enemy entered range. Ready to fire: ", ready_to_fire)
		
		# If ready to fire, attack immediately
		if ready_to_fire:
			fire_at_all_targets()

func _on_enemy_exited(body: Node2D) -> void:
	if body in enemies_in_range:
		enemies_in_range.erase(body)
		print("Enemy exited range. Enemies remaining: ", enemies_in_range.size())

func fire_at_all_targets() -> void:
	if enemies_in_range.is_empty() or not ready_to_fire or not laser_system:
		return
	
	print("LaserShip firing at ", enemies_in_range.size(), " enemies")
	
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
	print("LaserShip on cooldown for ", attack_cooldown, " seconds")
	
	# Schedule laser cleanup after laser_duration
	var cleanup_timer = get_tree().create_timer(laser_duration)
	cleanup_timer.timeout.connect(cleanup_all_lasers)

func cleanup_all_lasers() -> void:
	if laser_system:
		# Remove all lasers by passing empty array
		laser_system.target_enemies([])

func deal_damage_to_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		print("Dealt ", damage, " damage to ", enemy.name)

# Override the base attack method - we handle our own timing now
func attack() -> void:
	pass

func take_damage(amount: float) -> void:
	health -= amount
	print("New health: " + str(health))
	if health <= 0:
		var particle = death_particles.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		get_tree().current_scene.add_child(particle)
		if death_sfx:
			# Detach the audio player so it can finish playing
			death_sfx.get_parent().remove_child(death_sfx)
			get_tree().current_scene.add_child(death_sfx)
			death_sfx.play()
			# Optionally, queue_free the audio player after it finishes
			death_sfx.finished.connect(func(): death_sfx.queue_free())
		var parent = get_parent()
		print(parent)
		if parent and parent.has_method("remove_structure"):
			parent.remove_structure(self)

# Clean up when destroyed
func _exit_tree() -> void:
	cleanup_all_lasers()
