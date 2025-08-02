@tool
extends Node2D
class_name LaserSystem

## Speed at which lasers rotate to track targets
@export var rotation_speed := 10.0

## Base duration of the tween animation in seconds
var growth_time := 0.1
var color       := Color.WHITE: set = set_color
## Distance from center to start drawing lasers
var start_distance := 40.0
## Line width for the laser beams
var line_width := 4.0

@onready var casting_particles: GPUParticles2D = $CastingParticles
@onready var collision_particles: GPUParticles2D = $CollisionParticles
@onready var beam_particles: GPUParticles2D = $BeamParticles
@onready var line_2d: Line2D = %Line2D

# Dictionary to track active lasers by target
var active_lasers: Dictionary = {}
# Dictionary to track particle systems for each laser
var laser_particles: Dictionary = {}


func _ready() -> void:
	set_color(color)


# Call this to create lasers targeting all enemies in the area
func target_enemies(enemies: Array[Node2D]) -> void:
	# Remove lasers for enemies no longer in range
	var current_targets = active_lasers.keys()

	for target in current_targets:
		if not is_instance_valid(target) or not enemies.has(target):
			# Clean up directly without passing the freed object as parameter
			cleanup_laser_by_key(target)

	# Add lasers for new enemies
	for enemy in enemies:
		if not active_lasers.has(enemy):
			create_laser(enemy)


func create_laser(target: Node2D) -> void:
	if not is_instance_valid(target):
		return

	var laser = Line2D.new()
	laser.end_cap_mode = Line2D.LINE_CAP_ROUND
	laser.begin_cap_mode = Line2D.LINE_CAP_ROUND
	laser.width = 0.0  # Start at 0 width for animation
	laser.modulate = color
	laser.visible = true

	# Calculate initial direction and distance
	var direction = (target.global_position - global_position).normalized()
	var distance  = global_position.distance_to(target.global_position)

	var start_point = direction * start_distance
	var end_point   = direction * distance

	# Add points properly with correct positions
	laser.add_point(start_point)
	laser.add_point(start_point)  # Start collapsed at start_point

	add_child(laser)
	active_lasers[target] = laser

	# Create particle systems for this laser
	create_particles_for_laser(target, laser)

	# Animate appearance - this will grow the width and extend the line
	appear_laser(laser, target)

	# Start tracking the target
	track_target(target, laser)


func create_particles_for_laser(target: Node2D, laser: Line2D) -> void:
	# Create casting particles (at laser start)
	var casting_particles_instance = casting_particles.duplicate()
	casting_particles_instance.modulate = color
	casting_particles_instance.emitting = true
	add_child(casting_particles_instance)

	# Create collision particles (at laser end)
	var collision_particles_instance = collision_particles.duplicate()
	collision_particles_instance.modulate = color
	collision_particles_instance.emitting = true
	add_child(collision_particles_instance)

	# Create beam particles (along laser length)
	var beam_particles_instance = beam_particles.duplicate()
	beam_particles_instance.modulate = color
	beam_particles_instance.emitting = true
	add_child(beam_particles_instance)

	# Store particle references
	laser_particles[target] = {
		"casting": casting_particles_instance,
		"collision": collision_particles_instance,
		"beam": beam_particles_instance
	}


func track_target(target: Node2D, laser: Line2D) -> void:
	# Store references for the update function
	laser.set_meta("target", target)

	# Create a tween for continuous updates
	var tween = create_tween()
	tween.set_loops()  # Loop indefinitely

	# Store the tween reference so we can kill it later
	laser.set_meta("tracking_tween", tween)

	# Use tween_method with a parameter-accepting function
	tween.tween_method(
		func(value): update_laser_for_target(laser, value),
			0.0, 1.0, 0.016  # ~60fps updates
	)


func update_laser_for_target(laser: Line2D, _value: float) -> void:
	if not is_instance_valid(laser):
		return

	var target = laser.get_meta("target", null)
	if not is_instance_valid(target):
		return

	update_laser_direction(target, laser)


func update_laser_direction(target: Node2D, laser: Line2D) -> void:
	if not is_instance_valid(target) or not is_instance_valid(laser):
		return

	# Only update if laser has been fully created
	if laser.get_point_count() != 2:
		return

	var direction = (target.global_position - global_position).normalized()
	var distance  = global_position.distance_to(target.global_position)

	var start_point = direction * start_distance
	var end_point   = direction * distance

	# Update laser positions
	laser.set_point_position(0, start_point)
	laser.set_point_position(1, end_point)

	# Update particle positions and properties
	update_particles_for_laser(target, start_point, end_point, direction)


func update_particles_for_laser(target: Node2D, start_point: Vector2, end_point: Vector2, direction: Vector2) -> void:
	if not laser_particles.has(target):
		return

	var particles = laser_particles[target]

	# Update casting particles position (at laser start)
	if is_instance_valid(particles["casting"]):
		particles["casting"].position = start_point

	# Update collision particles position and rotation (at laser end)
	if is_instance_valid(particles["collision"]):
		particles["collision"].position = end_point
		# Rotate collision particles to face opposite of laser direction
		particles["collision"].rotation = direction.angle() + PI

	# Update beam particles position and emission box (along laser length)
	if is_instance_valid(particles["beam"]):
		var beam_center = start_point + (end_point - start_point) * 0.5
		particles["beam"].position = beam_center
		particles["beam"].rotation = direction.angle()

		# Modify the emission box extents to match laser length
		var laser_length = start_point.distance_to(end_point)
		if particles["beam"].process_material is ParticleProcessMaterial:
			var material = particles["beam"].process_material as ParticleProcessMaterial
			material.emission_box_extents.x = laser_length * 0.5
			material.emission_box_extents.y = line_width * 0.5  # Match laser width


func cleanup_laser_by_key(target_key) -> void:
	# Don't type the parameter - accept any key (even freed objects)
	if not active_lasers.has(target_key):
		return

	var laser = active_lasers[target_key]
	active_lasers.erase(target_key)

	# Stop tracking
	if is_instance_valid(laser) and laser.has_meta("tracking_tween"):
		var tween = laser.get_meta("tracking_tween")
		if tween and tween.is_valid():
			tween.kill()

	# Clean up particles (use target_key, even if invalid)
	cleanup_particles_by_key(target_key)

	# Animate disappearance
	if is_instance_valid(laser):
		disappear_laser(laser)
	else:
		# If laser is somehow invalid, just clean up immediately
		if laser:
			laser.queue_free()


func cleanup_particles_by_key(target_key) -> void:
	if not laser_particles.has(target_key):
		return

	var particles = laser_particles[target_key]

	# Stop emitting and clean up particles immediately
	for particle_type in particles.keys():
		var particle_system = particles[particle_type]
		if is_instance_valid(particle_system):
			particle_system.emitting = false
			# Queue free immediately instead of waiting
			particle_system.queue_free()

	laser_particles.erase(target_key)


func remove_laser(target: Node2D) -> void:
	# For valid targets, we can still use the typed version
	if is_instance_valid(target):
		cleanup_laser_by_key(target)
	else:
		# For invalid targets, find and clean up by reference
		cleanup_laser_by_key(target)


func remove_particles_for_laser(target: Node2D) -> void:
	if not laser_particles.has(target):
		return

	var particles = laser_particles[target]

	# Stop emitting and clean up particles
	for particle_type in particles.keys():
		var particle_system = particles[particle_type]
		if is_instance_valid(particle_system):
			particle_system.emitting = false
			# Remove particles after they finish their lifetime
			var cleanup_timer = get_tree().create_timer(2.0)  # Adjust based on particle lifetime
			cleanup_timer.timeout.connect(func(): if is_instance_valid(particle_system): particle_system.queue_free())

	laser_particles.erase(target)


func appear_laser(laser: Line2D, target: Node2D) -> void:
	laser.visible = true

	# Calculate the target end point
	var direction = (target.global_position - global_position).normalized()
	var distance  = global_position.distance_to(target.global_position)
	var end_point = direction * distance

	# Create tween for both width and length animation
	var tween = create_tween()
	tween.set_parallel(true)  # Allow multiple properties to animate simultaneously

	# Animate width from 0 to full width
	tween.tween_property(laser, "width", line_width, growth_time)

	# Animate the end point from start_point to target
	tween.tween_method(
		func(pos: Vector2): laser.set_point_position(1, pos),
			laser.get_point_position(0),  # Start from the first point
end_point,  # End at target
growth_time
    )




func disappear_laser(laser: Line2D) -> void:
	var tween = create_tween()
	tween.tween_property(laser, "width", 0.0, growth_time).from_current()
	tween.tween_callback(laser.queue_free)


func set_color(new_color: Color) -> void:
	color = new_color
	# Update existing lasers
	for laser in active_lasers.values():
		if is_instance_valid(laser):
			laser.modulate = new_color

	# Update existing particles
	for target in laser_particles.keys():
		var particles = laser_particles[target]
		for particle_system in particles.values():
			if is_instance_valid(particle_system):
				particle_system.modulate = new_color


# Clean up when the node is freed
func _exit_tree() -> void:
	var targets_to_cleanup = active_lasers.keys()
	for target_key in targets_to_cleanup:
		cleanup_laser_by_key(target_key)
