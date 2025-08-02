## Singleton that will be attached to the root node of the project
## Handles user input and game state management
class_name GameManager
extends Node2D

signal game_over()

@onready var music: AudioStreamPlayer = $Music

@export var loading_screen: PackedScene
var loading_screen_instance: Control = null

@onready var structure_manager = $StructureManager
@onready var orbit_manager = $OrbitManager
@onready var wave_manager: WaveManager = $WaveManager
@onready var upgrade_manager: Node = $UpgradeManager
@onready var structure_menu: Control = $UILayer/StructureSelectMenu
@onready var planet: Planet = $Planet
@onready var camera: Camera2D = $MainCamera

@export var pause_menu: PackedScene
var pause_menu_instance: Control = null

@onready var currency_ui: Control = $UILayer/CurrencyUI
var currency: int = 20

var wave_index: int = 0

var current_zoom: Vector2 = Vector2(1.0, 1.0)
var current_orbit: float = 350.0

var preview_instance: Node2D = null
var preview_type: String = ""

var hiscore: int = 0

# connects to wave manager signals and planet death signal for game over
func _ready():
	await _warm_up_everything()
	music.play()
	hiscore = load_hiscore()
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	planet.planet_destroyed.connect(_on_planet_destroyed)
	structure_menu.first_gunship_placed.connect(_on_first_gunship_placed)
	structure_menu.structure_type_selected.connect(_on_structure_type_selected)
	upgrade_manager.upgrade_choice_started.connect(_on_upgrade_choice_started)
	upgrade_manager.upgrade_choice_finished.connect(_on_upgrade_choice_finished)
	update_currency_ui()
	_update_gunship_cost_label(structure_manager.get_structure_cost("Gunship"))
	_update_lasership_cost_label(structure_manager.get_structure_cost("LaserShip"))
	_update_slowarea_cost_label(structure_manager.get_structure_cost("SlowArea"))
	_update_explosive_mine_cost_label(structure_manager.get_structure_cost("ExplosiveMine"))

# starts the delay timer before starting the next wave
# displays victory screen if there are no waves remaining
# adds new rings every 10 waves up to 5 rings
func _on_wave_completed():
	wave_index += 1
	currency += wave_index
	update_currency_ui()
	
	# Check for upgrade every 5th wave
	if wave_index % 5 == 0:  
		await safe_wait(1.0)
		upgrade_manager.start_upgrade_choice()
		return # don't start next wave until upgrade is chosen
	
	await _handle_ring_expansion_and_start_wave()

func _handle_ring_expansion_and_start_wave():
	# Add a ring and zoom out every 10 waves
	if wave_index % 10 == 0 and wave_index <= 50:
		current_zoom = current_zoom * 0.7
		await _zoom_camera_smoothly(current_zoom, 1.0)
		structure_menu.update_for_camera_zoom()
		current_orbit = current_orbit * 1.5
		orbit_manager.add_orbit(current_orbit)
	
	_start_next_wave()

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
		
	if event.is_action_pressed("pause"):
		_toggle_pause_menu()
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
			# Non-orbital structures (SlowArea, ExplosiveMine)
			snapped_pos = mouse_pos
			is_orbital = false
			orbit_idx = 0

		var new_structure = structure_manager.place_structure(structure_menu.selected_structure_type, snapped_pos, is_orbital, orbit_idx)
		if is_orbital and new_structure:
			orbit_manager.add_structure(new_structure, orbit_idx)
			if not structure_menu.slow_area_unlocked:
				structure_menu.unlock_slow_area()
		if new_structure:
			var placed_type = structure_menu.selected_structure_type # Store before clearing!
			currency -= structure_cost
			update_currency_ui()
			upgrade_manager.apply_upgrades_to_new_structure(new_structure)
			if placed_type == "Gunship":
				var new_gunship_cost = structure_cost + 10
				structure_manager.set_structure_cost("Gunship", new_gunship_cost)
				_update_gunship_cost_label(new_gunship_cost)
			elif placed_type == "LaserShip":
				var new_lasership_cost = structure_cost + 10
				structure_manager.set_structure_cost("LaserShip", new_lasership_cost)
				_update_lasership_cost_label(new_lasership_cost)
			elif placed_type == "SlowArea":
				var new_slowarea_cost = structure_cost + 5
				structure_manager.set_structure_cost("SlowArea", new_slowarea_cost)
				_update_slowarea_cost_label(new_slowarea_cost)
			elif placed_type == "ExplosiveMine":
				var new_mine_cost = structure_cost + 10
				structure_manager.set_structure_cost("ExplosiveMine", new_mine_cost)
				_update_explosive_mine_cost_label(new_mine_cost)
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
	get_tree().paused = false
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
		"ExplosiveMine":
			preview = preload("res://structures/scenes/explosive_mine.tscn").instantiate()
	if preview:
		if preview.has_node("Sprite"):
			preview.get_node("Sprite").modulate.a = 0.5
		if preview.has_node("BodyCollider"):
			preview.get_node("BodyCollider").disabled = true
		if preview.has_node("RangeArea"):
			preview.get_node("RangeArea").monitoring = false
		if preview.has_node("TriggerArea"):
			preview.get_node("TriggerArea").monitoring = false
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
	elif preview_type == "SlowArea" or preview_type == "ExplosiveMine":
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

func _update_slowarea_cost_label(cost: int) -> void:
	structure_menu.slow_area_cost_label.text = "-" + str(cost)

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

func _start_next_wave():
	var delay = wave_manager.get_next_wave_delay()
	await safe_wait(delay)
	wave_manager.start_wave(wave_index)

func _on_upgrade_choice_started():
	get_tree().paused = true

func _on_upgrade_choice_finished():
	get_tree().paused = false
	# Handle ring expansion after upgrade is finished
	await _handle_ring_expansion_and_start_wave()

func _update_explosive_mine_cost_label(cost: int) -> void:
	structure_menu.explosive_mine_cost_label.text = "-" + str(cost)

func _toggle_pause_menu():
	if pause_menu_instance:
		_resume_game()
	else:
		_show_pause_menu()

func _show_pause_menu():
	if pause_menu_instance:
		return
	pause_menu_instance = pause_menu.instantiate()
	pause_menu_instance.get_node("VolumeHbox/VolumeHslider").value = Settings.master_volume
	pause_menu_instance.get_node("VolumeHbox/VolumeHslider").value_changed.connect(_on_pause_menu_volume_changed)
	pause_menu_instance.get_node("ResumeButton").pressed.connect(_on_pause_menu_resume)
	pause_menu_instance.get_node("QuitButton").pressed.connect(_on_pause_menu_quit)
	
	if has_node("UILayer"):
		$UILayer.add_child(pause_menu_instance)
	else:
		add_child(pause_menu_instance)
	get_tree().paused = true

func _resume_game():
	if pause_menu_instance:
		pause_menu_instance.queue_free()
		pause_menu_instance = null
	get_tree().paused = false

func _on_pause_menu_resume():
	_resume_game()

func _on_pause_menu_quit():
	get_tree().quit()

func _on_pause_menu_volume_changed(value: float) -> void:
	Settings.master_volume = value
	Settings.save_settings()
	AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _warm_up_everything():
	print("WARMUP: Start")
	loading_screen_instance = loading_screen.instantiate()
	if has_node("UILayer"):
		$UILayer.add_child(loading_screen_instance)
	else:
		add_child(loading_screen_instance)
	print("WARMUP: Loading screen shown")
	await get_tree().process_frame

	# Position particles in the center of screen (behind loading screen)
	var center = get_viewport().get_visible_rect().size / 2

	# --- Warm up Gunship effects ---
	print("WARMUP: Gunship effects")
	var gunship_scene = preload("res://structures/scenes/gunship.tscn")
	var temp_gunship = gunship_scene.instantiate()
	temp_gunship.position = center
	temp_gunship.visible = true  # Make visible so GPU renders it
	add_child(temp_gunship)
	await get_tree().process_frame
	
	# Warm up attack particles (GPUParticles2D node)
	if temp_gunship.has_node("gunship_attack_vfx"):
		temp_gunship.get_node("gunship_attack_vfx").emitting = true
		await get_tree().process_frame
		await get_tree().process_frame  # Extra frame for shader compilation
		temp_gunship.get_node("gunship_attack_vfx").emitting = false
	
	# Warm up attack audio
	if temp_gunship.has_node("AttackSFX"):
		temp_gunship.get_node("AttackSFX").play()
		await get_tree().create_timer(0.01).timeout
		temp_gunship.get_node("AttackSFX").stop()
	
	# Warm up death particles (PackedScene) - RENDER ONSCREEN
	if temp_gunship.death_particles:
		var death_vfx = temp_gunship.death_particles.instantiate()
		death_vfx.position = center
		death_vfx.visible = true  # Make visible so GPU renders it
		add_child(death_vfx)
		death_vfx.emitting = true
		await get_tree().process_frame
		await get_tree().process_frame  # Extra frame for shader compilation
		death_vfx.queue_free()
	
	# Warm up death audio
	if temp_gunship.has_node("DeathSFX"):
		temp_gunship.get_node("DeathSFX").play()
		await get_tree().create_timer(0.01).timeout
		temp_gunship.get_node("DeathSFX").stop()
	
	temp_gunship.queue_free()
	await get_tree().process_frame

	# --- Warm up LaserShip effects ---
	print("WARMUP: LaserShip effects")
	var lasership_scene = preload("res://structures/scenes/laser_ship.tscn")
	var temp_lasership = lasership_scene.instantiate()
	temp_lasership.position = center
	temp_lasership.visible = true
	add_child(temp_lasership)
	await get_tree().process_frame

	# Create a dummy enemy for the laser to target
	print("WARMUP: Creating dummy enemy for laser targeting")
	var dummy_enemy = Node2D.new()
	dummy_enemy.position = center + Vector2(200, 0)  # Position it away from laser ship
	add_child(dummy_enemy)
	await get_tree().process_frame

	# IM PREFIRING MY LAZERS
	print("WARMUP: Firing laser system")
	if temp_lasership.has_node("LaserSystem"):
		var laser_system = temp_lasership.get_node("LaserSystem")
		var typed_enemies: Array[Node2D] = [dummy_enemy]  # Properly typed array
		laser_system.target_enemies(typed_enemies)  # Pass typed array
		await get_tree().process_frame
		await get_tree().process_frame

	# Warm up attack audio
	if temp_lasership.has_node("AttackSFX"):
		temp_lasership.get_node("AttackSFX").play()
		await get_tree().create_timer(0.01).timeout
		temp_lasership.get_node("AttackSFX").stop()

	# Clean up the laser beams and dummy enemy
	print("WARMUP: Cleaning up laser system")
	if temp_lasership.has_node("LaserSystem"):
		var empty_enemies: Array[Node2D] = []  # Properly typed empty array
		temp_lasership.get_node("LaserSystem").target_enemies(empty_enemies)  # Pass typed array
		await get_tree().process_frame

	dummy_enemy.queue_free()
	await get_tree().process_frame

	# Warm up death particles - RENDER ONSCREEN
	if temp_lasership.death_particles:
		var death_vfx = temp_lasership.death_particles.instantiate()
		death_vfx.position = center
		death_vfx.visible = true
		add_child(death_vfx)
		death_vfx.emitting = true
		await get_tree().process_frame
		await get_tree().process_frame
		death_vfx.queue_free()

	# Warm up death audio
	if temp_lasership.has_node("DeathSFX"):
		temp_lasership.get_node("DeathSFX").play()
		await get_tree().create_timer(0.01).timeout
		temp_lasership.get_node("DeathSFX").stop()

	temp_lasership.queue_free()
	await get_tree().process_frame

	# --- Warm up ExplosiveMine effects ---
	print("WARMUP: Mine explosion effects")
	var mine_scene = preload("res://structures/scenes/explosive_mine.tscn")
	var temp_mine = mine_scene.instantiate()
	temp_mine.position = center
	temp_mine.visible = true
	add_child(temp_mine)
	await get_tree().process_frame
	
	# Warm up explosion particles - RENDER ONSCREEN
	if temp_mine.explosion_particles:
		var explosion_vfx = temp_mine.explosion_particles.instantiate()
		explosion_vfx.position = center
		explosion_vfx.visible = true
		add_child(explosion_vfx)
		explosion_vfx.emitting = true
		await get_tree().process_frame
		await get_tree().process_frame
		explosion_vfx.queue_free()
	
	temp_mine.queue_free()
	await get_tree().process_frame

	# --- Warm up Enemy death effects ---
	print("WARMUP: Enemy death effects")
	
	# Asteroid death effects
	var asteroid_scene = preload("res://enemies/scenes/asteroid.tscn")
	var temp_asteroid = asteroid_scene.instantiate()
	temp_asteroid.position = center
	temp_asteroid.visible = true
	add_child(temp_asteroid)
	await get_tree().process_frame
	
	# Warm up death particles - RENDER ONSCREEN
	if temp_asteroid.death_particles:
		var death_vfx = temp_asteroid.death_particles.instantiate()
		death_vfx.position = center
		death_vfx.visible = true
		add_child(death_vfx)
		death_vfx.emitting = true
		await get_tree().process_frame
		await get_tree().process_frame
		death_vfx.queue_free()
	
	# Warm up death audio
	if temp_asteroid.has_node("DeathSFX"):
		temp_asteroid.get_node("DeathSFX").play()
		await get_tree().create_timer(0.05).timeout
		temp_asteroid.get_node("DeathSFX").stop()
	
	temp_asteroid.queue_free()
	await get_tree().process_frame
	
	# Big asteroid
	var big_asteroid_scene = preload("res://enemies/scenes/big_asteroid.tscn")
	var temp_big_asteroid = big_asteroid_scene.instantiate()
	temp_big_asteroid.position = center
	temp_big_asteroid.visible = true
	add_child(temp_big_asteroid)
	await get_tree().process_frame
	
	if temp_big_asteroid.death_particles:
		var death_vfx = temp_big_asteroid.death_particles.instantiate()
		death_vfx.position = center
		death_vfx.visible = true
		add_child(death_vfx)
		death_vfx.emitting = true
		await get_tree().process_frame
		await get_tree().process_frame
		death_vfx.queue_free()
	
	temp_big_asteroid.queue_free()
	await get_tree().process_frame

	# Comet (if different from asteroid)
	var comet_scene = preload("res://enemies/scenes/comet.tscn")
	var temp_comet = comet_scene.instantiate()
	temp_comet.position = center
	temp_comet.visible = true
	add_child(temp_comet)
	await get_tree().process_frame
	
	if temp_comet.death_particles:
		var death_vfx = temp_comet.death_particles.instantiate()
		death_vfx.position = center
		death_vfx.visible = true
		add_child(death_vfx)
		death_vfx.emitting = true
		await get_tree().process_frame
		await get_tree().process_frame
		death_vfx.queue_free()
	
	temp_comet.queue_free()
	await get_tree().process_frame

	print("WARMUP: Waiting for effects to finish")
	await get_tree().create_timer(0.3).timeout
	
	print("WARMUP: Hiding loading screen")
	loading_screen_instance.queue_free()
	loading_screen_instance = null
	await get_tree().process_frame
	print("WARMUP: Done")
