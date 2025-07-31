## Singleton that will be attached to the root node of the project
## Handles user input and game state management
class_name GameManager
extends Node2D

@onready var structure_manager = $StructureManager
@onready var orbit_manager = $OrbitManager
@onready var wave_manager: WaveManager = $WaveManager
@onready var structure_menu: Control = $UILayer/StructureSelectMenu
@onready var planet: Planet = $Planet
@onready var camera: Camera2D = $MainCamera

var wave_index: int = 0

# connects to wave manager signals and planet death signal for game over
func _ready():
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.start_wave(wave_index)
	planet.planet_destroyed.connect(_on_planet_destroyed)

# starts the delay timer before starting the next wave
# displays victory screen if there are no waves remaining
# adds 2nd ring after wave 5
func _on_wave_completed():
	wave_index += 1
	if wave_index == 5:
		await _zoom_camera_smoothly(Vector2(0.7, 0.7), 1.0) # zoom camera out for new ring
		orbit_manager.add_orbit(500.0) # add new ring fter wave 5
	if wave_index < wave_manager.waves.size():
		var delay = wave_manager.waves[wave_index - 1].time_to_next_wave
		await get_tree().create_timer(delay).timeout
		wave_manager.start_wave(wave_index)
	else:
		_show_victory_screen()

func _zoom_camera_smoothly(target_zoom: Vector2, duration: float) -> void:
	var start_zoom = camera.zoom
	var t = 0.0
	while t < duration:
		camera.zoom = start_zoom.lerp(target_zoom, t / duration)
		await get_tree().process_frame
		t += get_process_delta_time()
	camera.zoom = target_zoom

func _show_victory_screen():
	var label = Label.new()
	label.text = "VICTORY!"
	label.modulate = Color(0, 1, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = get_viewport().get_visible_rect().size / 2
	add_child(label)

func _process(delta):
	structure_manager.update_all(delta)

# On left click it places a structure, orbital structures are added to the orbit manager and snap to the path
# SPACE = Reverse orbit direction
func _unhandled_input(event):  # _unhandled_input automatically ignores input into the selection menu for us
	if event.is_action_pressed("reverse_orbit"):
		orbit_manager.reverse_orbit()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if structure_menu.selected_structure_type == "":
			return

		var mouse_pos = get_viewport().get_mouse_position()
		var snapped_pos: Vector2
		var is_orbital := false

		# Only snap to orbit if the selected structure is orbital
		if structure_menu.selected_structure_type == "Gunship":
			var center = orbit_manager.orbit_center
			var mouse_dist = mouse_pos.distance_to(center)
			var orbit_idx = orbit_manager.get_closest_orbit(mouse_pos)
			var radius = orbit_manager.orbit_radii[orbit_idx]
			var direction = (mouse_pos - center).normalized()
			snapped_pos = center + direction * radius
			is_orbital = true
		else:
			snapped_pos = mouse_pos
			is_orbital = false

		var new_structure = structure_manager.place_structure(structure_menu.selected_structure_type, snapped_pos, is_orbital)
		if is_orbital and new_structure:
			orbit_manager.add_structure(new_structure, new_structure.orbit_idx)

# called when planet health reaches 0
# displays game over screen
func _on_planet_destroyed():
	var label = Label.new()
	label.text = "GAME OVER"
	label.modulate = Color(1, 0, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = get_viewport().get_visible_rect().size / 2
	add_child(label)
