## Singleton that will be attached to the root node of the project
## Handles user input and game state management
class_name GameManager
extends Node2D

signal game_over()

@onready var structure_manager = $StructureManager
@onready var orbit_manager = $OrbitManager
@onready var wave_manager: WaveManager = $WaveManager
@onready var structure_menu: Control = $UILayer/StructureSelectMenu
@onready var planet: Planet = $Planet
@onready var camera: Camera2D = $MainCamera

@onready var currency_ui: Control = $UILayer/CurrencyUI
var currency: int = 300

var wave_index: int = 0

var current_zoom: Vector2 = Vector2(1.0, 1.0)
var current_orbit: float = 350.0

var preview_instance: Node2D = null
var preview_type: String = ""

var hiscore: int = 0

# connects to wave manager signals and planet death signal for game over
func _ready():
	hiscore = load_hiscore()
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	planet.planet_destroyed.connect(_on_planet_destroyed)
	structure_menu.first_gunship_placed.connect(_on_first_gunship_placed)
	structure_menu.structure_type_selected.connect(_on_structure_type_selected)
	update_currency_ui()
	_update_gunship_cost_label(structure_manager.get_structure_cost("Gunship"))
	_update_lasership_cost_label(structure_manager.get_structure_cost("LaserShip"))

# starts the delay timer before starting the next wave
# displays victory screen if there are no waves remaining
# adds new rings every 10 waves up to 5 rings
func _on_wave_completed():
	wave_index += 1
	currency += 5 + wave_index
	update_currency_ui()
	# Add a ring and zoom out every 5 waves
	if wave_index % 10 == 0 and wave_index <= 50:
		current_zoom = current_zoom * 0.7
		await _zoom_camera_smoothly(current_zoom, 1.0)
		structure_menu.update_for_camera_zoom()
		current_orbit = current_orbit * 1.5
		orbit_manager.add_orbit(current_orbit)
	var delay = wave_manager.get_next_wave_delay()
	await safe_wait(delay)
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
	label.anchor_left = 0.5
	label.anchor_top = 0.5
	label.anchor_right = 0.5
	label.anchor_bottom = 0.5
	label.pivot_offset = Vector2(0, 0)
	label.position = get_viewport().get_visible_rect().size / 2
	label.scale = Vector2(0, 0)
	add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1, 1), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _process(delta):
	if not get_tree():
		return
	structure_manager.update_all(delta)
	_update_preview_position()

# On left click it places a structure, orbital structures are added to the orbit manager and snap to the path
# SPACE = Reverse orbit direction
func _unhandled_input(event):
	if not get_tree():
		return
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
		if structure_menu.selected_structure_type == "Gunship" or structure_menu.selected_structure_type == "LaserShip":
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
			var placed_type = structure_menu.selected_structure_type # Store before clearing!
			currency -= structure_cost
			update_currency_ui()
			if placed_type == "Gunship":
				var new_gunship_cost = structure_cost + 10
				structure_manager.set_structure_cost("Gunship", new_gunship_cost)
				_update_gunship_cost_label(new_gunship_cost)
			elif placed_type == "LaserShip":
				var new_lasership_cost = structure_cost + 10
				structure_manager.set_structure_cost("LaserShip", new_lasership_cost)
				_update_lasership_cost_label(new_lasership_cost)
			structure_menu.clear_selection()
			_remove_preview()

# called when planet health reaches 0
# displays game over screen
# called when planet health reaches 0
# displays game over screen with play again button
func _on_planet_destroyed():
	wave_manager.remove_all_active_enemies()
	game_over.emit()
	var game_over_container = Control.new()
	game_over_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_container.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(200, 100)
	
	var waves_completed = wave_index
	var is_new_hiscore: bool = false
	if waves_completed > hiscore:
		hiscore = waves_completed
		save_hiscore(hiscore)
		is_new_hiscore = true
	
	var label = Label.new()
	label.text = "GAME OVER"
	label.modulate = Color(1, 0, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var hiscore_label = Label.new()
	hiscore_label.text = "Hiscore: " + str(hiscore) + " waves completed."
	hiscore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hiscore_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hiscore_label.modulate = Color(0, 1, 0) if is_new_hiscore else Color(1, 1, 1)
	
	var play_again_button = Button.new()
	play_again_button.text = "Play Again"
	play_again_button.custom_minimum_size = Vector2(120, 40)
	play_again_button.pressed.connect(_on_play_again_pressed)
	
	vbox.add_child(label)
	vbox.add_child(hiscore_label)
	vbox.add_child(play_again_button)
	game_over_container.add_child(vbox)
	
	if has_node("UILayer"):
		$UILayer.add_child(game_over_container)
	else:
		add_child(game_over_container)
	
	# Set pivot to center of the screen and start at 0 scale
	game_over_container.pivot_offset = get_viewport().get_visible_rect().size / 2
	game_over_container.scale = Vector2(0, 0)
	game_over_container.position.x -= vbox.size.x
	game_over_container.position.y -= vbox.size.y
	
	# Tween the entire container
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(game_over_container, "scale", Vector2(2, 2), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true
	
# restarts the current scene when play again button is pressed
func _on_play_again_pressed():
	get_tree().call_deferred("reload_current_scene")

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
		"LaserShip":
			preview = preload("res://structures/scenes/laser_ship.tscn").instantiate()
		"SlowArea":
			preview = preload("res://structures/scenes/slow_area.tscn").instantiate()
	if preview:
		if preview.has_node("Sprite"):
			preview.get_node("Sprite").modulate.a = 0.5
		if preview.has_node("BodyCollider"):
			preview.get_node("BodyCollider").disabled = true
		if preview.has_node("RangeArea"):
			preview.get_node("RangeArea").monitoring = false
		if preview.has_node("Range"):
			preview.get_node("Range").monitoring = false
	return preview

func _update_preview_position() -> void:
	if not preview_instance or preview_type == "":
		return
	var mouse_pos = camera.get_global_mouse_position()
	if preview_type == "Gunship" or preview_type == "LaserShip":
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

func _update_lasership_cost_label(cost: int) -> void:
	structure_menu.laser_ship_cost_label.text = "-" + str(cost)

func safe_wait(time: float):
	if not get_tree() or not is_inside_tree():
		return
	await get_tree().create_timer(time).timeout

func save_hiscore(value: int) -> void:
	var save = FileAccess.open("user://hiscore.save", FileAccess.WRITE)
	save.store_32(value)
	save.close()

func load_hiscore() -> int:
	if FileAccess.file_exists("user://hiscore.save"):
		var save = FileAccess.open("user://hiscore.save", FileAccess.READ)
		var value = save.get_32()
		save.close()
		return value
	return 0

func _on_first_gunship_placed():
	wave_manager.start_first_wave.emit()
