class_name LaserShip
extends AttackStructure

@export var laser_color := Color.RED
@export var laser_width := 4.0
@export var start_distance := 20.0
## How long lasers take to appear/disappear
@export var laser_grow_time := 0.1
## How long lasers stay visible during attack
@export var laser_duration := 0.3

# Dictionary to track active lasers
var active_lasers: Dictionary = {}
var enemies_in_range: Array[Node2D] = []
# Track if the ship is ready to fire (cooldown expired)
var ready_to_fire: bool = true

@onready var range_area: Area2D = $Range

func _ready() -> void:
	super._ready()
	
	# Connect area signals for enemy detection
	if range_area:
		range_area.body_entered.connect(_on_enemy_entered)
		range_area.body_exited.connect(_on_enemy_exited)
	
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
	
	# Update laser positions to track moving enemies (only if lasers are active)
	update_laser_tracking()

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
	if enemies_in_range.is_empty() or not ready_to_fire:
		return
	
	print("LaserShip firing at ", enemies_in_range.size(), " enemies")
	
	# Create lasers for all enemies in range and deal damage
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			create_laser_for_enemy(enemy)
			deal_damage_to_enemy(enemy)
	
	# Put the weapon on cooldown AFTER firing
	ready_to_fire = false
	cooldown_timer = attack_cooldown
	print("LaserShip on cooldown for ", attack_cooldown, " seconds")
	
	# Schedule laser cleanup after laser_duration
	var cleanup_timer = get_tree().create_timer(laser_duration)
	cleanup_timer.timeout.connect(cleanup_all_lasers)

func create_laser_for_enemy(enemy: Node2D) -> void:
	if not is_instance_valid(enemy) or active_lasers.has(enemy):
		return
	
	# Create laser line
	var laser = Line2D.new()
	laser.width = 0.0  # Start invisible
	laser.modulate = laser_color
	laser.z_index = 1  # Draw above other elements
	
	# Calculate direction and distance to enemy
	var direction = (enemy.global_position - global_position).normalized()
	var distance = global_position.distance_to(enemy.global_position)
	var start_point = direction * start_distance
	var end_point = direction * distance
	
	# Set laser points
	laser.add_point(start_point)
	laser.add_point(end_point)
	
	add_child(laser)
	active_lasers[enemy] = laser
	
	# Animate laser appearance
	animate_laser_appear(laser)

func animate_laser_appear(laser: Line2D) -> void:
	laser.visible = true
	var tween = create_tween()
	tween.tween_property(laser, "width", laser_width, laser_grow_time)

func animate_laser_disappear(laser: Line2D) -> void:
	var tween = create_tween()
	tween.tween_property(laser, "width", 0.0, laser_grow_time)
	tween.tween_callback(laser.queue_free)

func update_laser_tracking() -> void:
	# Update each laser to point at its target (only while lasers are active)
	for enemy in active_lasers.keys():
		if not is_instance_valid(enemy):
			# Clean up invalid enemies
			var laser = active_lasers[enemy]
			active_lasers.erase(enemy)
			if is_instance_valid(laser):
				laser.queue_free()
			continue
		
		var laser = active_lasers[enemy]
		if not is_instance_valid(laser):
			active_lasers.erase(enemy)
			continue
		
		# Calculate direction and distance to enemy
		var direction = (enemy.global_position - global_position).normalized()
		var distance = global_position.distance_to(enemy.global_position)
		
		# Update laser points
		laser.points[0] = direction * start_distance
		laser.points[1] = direction * distance

func cleanup_all_lasers() -> void:
	# Remove all active lasers
	for enemy in active_lasers.keys():
		var laser = active_lasers[enemy]
		if is_instance_valid(laser):
			animate_laser_disappear(laser)
	
	active_lasers.clear()

func deal_damage_to_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		print("Dealt ", damage, " damage to ", enemy.name)

# Override the base attack method - we handle our own timing now
func attack() -> void:
	# This method is no longer used since we handle timing differently
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
		var parent = get_parent()
		print(parent)
		if parent and parent.has_method("remove_structure"):
			parent.remove_structure(self)

# Clean up when destroyed
func _exit_tree() -> void:
	cleanup_all_lasers()
