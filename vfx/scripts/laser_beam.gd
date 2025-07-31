@tool
extends Node2D
class_name LaserSystem

## Speed at which lasers rotate to track targets
@export var rotation_speed := 10.0
## Base duration of the tween animation in seconds
@export var growth_time := 0.1
@export var color := Color.WHITE: set = set_color
## Distance from center to start drawing lasers
@export var start_distance := 40.0
## Line width for the laser beams
@export var line_width := 8.0

# Dictionary to track active lasers by target
var active_lasers: Dictionary = {}
var laser_scene: PackedScene

func _ready() -> void:
	set_color(color)
	# Create a simple laser scene we can instantiate
	create_laser_scene()

func create_laser_scene() -> void:
	# This creates a simple laser Line2D that we can instantiate
	pass

# Call this to create lasers targeting all enemies in the area
func target_enemies(enemies: Array[Node2D]) -> void:
	# Remove lasers for enemies no longer in range
	var current_targets = active_lasers.keys()
	for target in current_targets:
		if not enemies.has(target) or not is_instance_valid(target):
			remove_laser(target)
	
	# Add lasers for new enemies
	for enemy in enemies:
		if not active_lasers.has(enemy):
			create_laser(enemy)

func create_laser(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
		
	var laser = Line2D.new()
	laser.width = line_width
	laser.modulate = color
	laser.add_point(Vector2.RIGHT * start_distance)
	laser.add_point(Vector2.RIGHT * start_distance)  # Start collapsed
	
	add_child(laser)
	active_lasers[target] = laser
	
	# Animate appearance
	appear_laser(laser)
	
	# Start tracking the target
	track_target(target, laser)

func track_target(target: Node2D, laser: Line2D) -> void:
	# Create a tween for smooth rotation/tracking
	var tween = create_tween()
	tween.set_loops()  # Loop indefinitely
	
	# Store the tween reference so we can kill it later
	laser.set_meta("tracking_tween", tween)
	
	# Update laser direction every frame
	tween.tween_method(
		func(): update_laser_direction(target, laser),
		0.0, 1.0, 0.016  # ~60fps updates
	)

func update_laser_direction(target: Node2D, laser: Line2D) -> void:
	if not is_instance_valid(target) or not is_instance_valid(laser):
		return
		
	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)
	
	laser.points[0] = direction * start_distance
	laser.points[1] = direction * distance

func remove_laser(target: Node2D) -> void:
	if not active_lasers.has(target):
		return
		
	var laser = active_lasers[target]
	active_lasers.erase(target)
	
	# Stop tracking
	if laser.has_meta("tracking_tween"):
		var tween = laser.get_meta("tracking_tween")
		if tween and tween.is_valid():
			tween.kill()
	
	# Animate disappearance
	disappear_laser(laser)

func appear_laser(laser: Line2D) -> void:
	laser.visible = true
	var tween = create_tween()
	tween.tween_property(laser, "width", line_width, growth_time * 2.0).from(0.0)

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

# Clean up when the node is freed
func _exit_tree() -> void:
	for target in active_lasers.keys():
		remove_laser(target)
