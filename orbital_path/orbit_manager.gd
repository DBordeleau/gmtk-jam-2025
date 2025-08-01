## Manages orbital structures and updates their positions along a circular path around the center of the screen.
class_name OrbitManager
extends Node2D

var structures: Array = []
var orbit_center: Vector2 = Vector2.ZERO

# start with one ring with a radius of 350
var orbit_radii: Array[float] = [350.0]
var orbit_direction: int = 1

var orbit_speed_multipliers: Array[float] = [1.0]

@onready var camera: Camera2D = get_tree().get_root().get_node("GameManager/MainCamera")
var last_zoom: Vector2 = Vector2.ONE

# sets orbit to center of the screen
func _ready():
	var viewport = get_viewport()
	orbit_center = viewport.get_visible_rect().size / 2
	queue_redraw()
	
# adds a reference to the structure to the structures array
# also calculates an initial angle for it based on its position
func add_structure(structure: Structure, orbit_idx: int) -> void:
	if structure.is_orbital:
		var radius = orbit_radii[orbit_idx]
		var direction = (structure.position - orbit_center).normalized()
		var angle = atan2(direction.y, direction.x)
		structure.set("orbit_angle", angle)
		structure.set("orbit_radius", radius)
		structure.set("orbit_idx", orbit_idx)
		structures.append(structure)
		
func remove_structure(structure: Structure) -> void:
	structures.erase(structure)

# adds another orbital ring
func add_orbit(radius: float) -> void:
	orbit_radii.append(radius)
	var last_multiplier = orbit_speed_multipliers[-1]
	orbit_speed_multipliers.append(last_multiplier * 0.85)
	queue_redraw()

# returns the orbit that is closest to the mouse
func get_closest_orbit(mouse_pos: Vector2) -> int:
	var min_dist = INF
	var closest_idx = 0
	for i in range(orbit_radii.size()):
		var dist = abs(mouse_pos.distance_to(orbit_center) - orbit_radii[i])
		if dist < min_dist:
			min_dist = dist
			closest_idx = i
	return closest_idx

# called every frame to smoothly animate structures along the orbital path
func _process(delta):
	if camera and camera.zoom != last_zoom:
		last_zoom = camera.zoom
		queue_redraw()
	for structure in structures:
		if structure.is_orbital:
			var angle = structure.get("orbit_angle")
			var radius = structure.get("orbit_radius")
			var orbit_idx = structure.get("orbit_idx")
			var multiplier = orbit_speed_multipliers[orbit_idx]
			angle += delta * structure.speed * multiplier * orbit_direction
			structure.set("orbit_angle", angle)
			structure.position = orbit_center + Vector2(cos(angle), sin(angle)) * radius
			
# moves all existing structures along the orbital path
func update_positions() -> void:
	for i in range(structures.size()):
		var structure = structures[i]
		if structure.is_orbital:
			# Evenly distribute structures around the orbit
			var angle = (float(i) / structures.size()) * TAU
			var pos = orbit_center + Vector2(cos(angle), sin(angle)) * orbit_radii[i]
			structure.position = pos

# called by game_manager when the player does the reverse_orbit input action
func reverse_orbit() -> void:
	orbit_direction *= -1

# draw a grey circle to indicate path (temporary)
func _draw():
	var segments := 128
	var base_width = 4.0
	var zoom_scale = 1.0
	if camera:
		zoom_scale = (camera.zoom.x + camera.zoom.y) * 0.5
	var line_width = base_width * zoom_scale * 2.0 
	line_width = clamp(line_width, 4.0, 32.0) # prevents lines from getting too thin or too thick
	for radius in orbit_radii:
		draw_arc(
			orbit_center,
			radius,
			0,
			TAU,
			segments,
			Color(1, 1, 1, 1),
			line_width
		)
