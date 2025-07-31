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

@onready var currency_ui: Control = $Planet/CurrencyUI
var currency: int = 20

var wave_index: int = 0

var current_zoom: Vector2 = Vector2(1.0, 1.0)
var current_orbit: float = 350.0

var preview_instance: Node2D = null
var preview_type: String = ""

# connects to wave manager signals and planet death signal for game over
func _ready():
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	wave_manager.start_wave(wave_index)
	planet.planet_destroyed.connect(_on_planet_destroyed)
	structure_menu.structure_type_selected.connect(_on_structure_type_selected)
	update_currency_ui()
	_update_gunship_cost_label(structure_manager.get_structure_cost("Gunship"))

# starts the delay timer before starting the next wave
# displays victory screen if there are no waves remaining
# adds 2nd ring after wave 5
func _on_wave_completed():
	wave_index += 1
	currency += 5 + wave_index
	update_currency_ui()
	# Add a ring and zoom out every 5 waves
	if wave_index % 5 == 0:
		current_zoom = current_zoom * 0.7
		await _zoom_camera_smoothly(current_zoom, 1.0)
		structure_menu.update_for_camera_zoom()
		current_orbit = current_orbit * 1.5
		orbit_manager.add_orbit(current_orbit)
	var delay = wave_manager.get_next_wave_delay()
	await get_tree().create_timer(delay).timeout
	wave_manager.start_wave(wave_index)

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
	_update_preview_position()

# On left click it places a structure, orbital structures are added to the orbit manager and snap to the path
# SPACE = Reverse orbit direction
func _unhandled_input(event):
	if event.is_action_pressed("reverse_orbit"):
		orbit_manager.reverse_orbit()
		
	if event.is_action_pressed("toggle_structure_select_menu"):
		structure_menu.toggle_menu()
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if structure_menu.selected_structure_type == "":
			return

		# ensure player has enough currency to place structure
		var structure_cost = structure_manager.get_structure_cost(structure_menu.selected_structure_type)
		if currency < structure_cost:
			print("Not enough currency to place structure!")
			return

		var mouse_pos = camera.get_global_mouse_position()
		var snapped_pos: Vector2
		var is_orbital := false
		var orbit_idx := 0 

		# only snap to orbit if the selected structure is orbital
		if structure_menu.selected_structure_type == "Gunship":
			var center = orbit_manager.orbit_center
			orbit_idx = orbit_manager.get_closest_orbit(mouse_pos)
			var radius = orbit_manager.orbit_radii[orbit_idx]
			var direction = (mouse_pos - center).normalized()
			snapped_pos = center + direction * radius
			is_orbital = true
		else:
			snapped_pos = mouse_pos
			is_orbital = false
			orbit_idx = 0 # default for non-orbital

		var new_structure = structure_manager.place_structure(structure_menu.selected_structure_type, snapped_pos, is_orbital, orbit_idx)
		if is_orbital and new_structure:
			orbit_manager.add_structure(new_structure, orbit_idx)
			if not structure_menu.slow_area_unlocked:
				structure_menu.unlock_slow_area()
		if new_structure:
			currency -= structure_cost
			update_currency_ui()
			# increase gunship cost when placing a gunship
			if structure_menu.selected_structure_type == "Gunship":
				var new_cost = structure_cost + 10
				structure_manager.set_structure_cost("Gunship", new_cost)
				_update_gunship_cost_label(new_cost)
			_remove_preview()

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

# updates currency label and the structure select buttons
func update_currency_ui():
	currency_ui.currency_label.text = str(currency)
	structure_menu.update_buttons(currency)
	
# called every time wave_manager emits the enemy_killed signal
func _on_enemy_killed():
	currency += 1
	update_currency_ui()

func _on_structure_type_selected(type: String) -> void:
	_remove_preview()
	if type == "":
		return
	preview_type = type
	preview_instance = _create_preview(type)
	add_child(preview_instance)
	
func _create_preview(type: String) -> Node2D:
	var preview: Node2D = null
	match type:
		"Gunship":
			preview = preload("res://structures/scenes/gunship.tscn").instantiate()
		"SlowArea":
			preview = preload("res://structures/scenes/slow_area.tscn").instantiate()
	if preview:
		if preview.has_node("Sprite"):
			preview.get_node("Sprite").modulate.a = 0.5
	return preview

func _update_preview_position() -> void:
	if not preview_instance or preview_type == "":
		return
	var mouse_pos = camera.get_global_mouse_position()
	if preview_type == "Gunship":
		var center = orbit_manager.orbit_center
		var orbit_idx = orbit_manager.get_closest_orbit(mouse_pos)
		var radius = orbit_manager.orbit_radii[orbit_idx]
		var direction = (mouse_pos - center).normalized()
		preview_instance.position = center + direction * radius
	elif preview_type == "SlowArea":
		preview_instance.position = mouse_pos

func _remove_preview():
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
		preview_type = ""

# updates the gunship cost label in the structure select menu
func _update_gunship_cost_label(cost: int) -> void:
	structure_menu.gunship_cost_label.text = "-" + str(cost)
