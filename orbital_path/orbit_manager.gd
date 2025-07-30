## Manages orbital structures and updates their positions along a circular path around the center of the screen.
class_name OrbitManager
extends Node2D

var structures: Array = []
var orbit_center: Vector2 = Vector2.ZERO
var orbit_radius: float = 350.0 # should this be dynamic to match different display sizes or will it affect gameplay??
var orbit_direction: int = 1 # 1 for clockwise, -1 for counter-clockwise

# sets orbit to center of the screen
func _ready():
	var viewport = get_viewport()
	orbit_center = viewport.get_visible_rect().size / 2
	queue_redraw()  # Fixed: replaced update() with queue_redraw()
	
# adds a reference to the structure to the structures array
# also calculates an initial angle for it based on its position
func add_structure(structure: Structure) -> void:
	if structure.is_orbital:
		var direction = (structure.position - orbit_center).normalized()
		var angle = atan2(direction.y, direction.x)
		structure.set("orbit_angle", angle)
		structures.append(structure)

# called every frame to smoothly animate structures along the orbital path
func _process(delta):
	for structure in structures:
		if structure.is_orbital:
			var angle = structure.get("orbit_angle")
			angle += delta * structure.speed * orbit_direction
			structure.set("orbit_angle", angle)
			structure.position = orbit_center + Vector2(cos(angle), sin(angle)) * orbit_radius
			
# moves all existing structures along the orbital path
func update_positions() -> void:
	for i in range(structures.size()):
		var structure = structures[i]
		if structure.is_orbital:
			# Evenly distribute structures around the orbit
			var angle = (float(i) / structures.size()) * TAU
			var pos = orbit_center + Vector2(cos(angle), sin(angle)) * orbit_radius
			structure.position = pos

# called by game_manager when the player does the reverse_orbit input action
func reverse_orbit() -> void:
	orbit_direction *= -1

# draw a grey circle to indicate path (temporary)
func _draw():
	var segments := 128
	draw_arc(
		orbit_center,
		orbit_radius,
		0,
		TAU,
		segments,
		Color(1, 1, 1, 1),
		2.0 # thickness
	)
