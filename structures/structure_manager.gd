## Manages all structures placed in the scene. Structures can be orbital (placed on the loop) or static (placed anywhere in scene and don't move) 
## Structure types:
# AttackStructures attack nearby enemies automatically
# SlowStructures slow nearby enemies automatically
class_name StructureManager
extends Node

@export var orbit_manager: OrbitManager

var structures: Array = []
var shield_active: bool = false
var shield_timer: float = 0.0
var shield_duration: float = 1.0
var shield_cost: int = 10

var structure_costs: Dictionary = {
						  "Gunship": 10,
						  "SlowArea": 5,
						  "LaserShip": 30,
						  "ExplosiveMine": 10,
					  }

var structure_map: Dictionary = {
						"Gunship": preload("res://structures/scenes/gunship.tscn"),
						"SlowArea": preload("res://structures/scenes/slow_area.tscn"),
						"LaserShip": preload("res://structures/scenes/laser_ship.tscn"),
						"ExplosiveMine": preload("res://structures/scenes/explosive_mine.tscn")
					}


# Called by the GameManager if the user left clicks with a structure selected
# Adds the placed structure to the array, adds it to the structure group and then adds it to the scene
# returns the placed structure
func place_structure(type: String, position: Vector2, is_orbital: bool, orbit_idx: int = 0) -> Structure:
	var structure: Structure = null

	match type:
		"Gunship":
			var structure_scene: PackedScene = preload("res://structures/scenes/gunship.tscn")
			var temp_structure: Node         = structure_scene.instantiate()
			# Check for overlapping body colliders with other gunships/laserships on same orbit
			for existing in structures:
				if (existing is Gunship or existing is LaserShip) and existing.is_orbital and existing.orbit_idx == orbit_idx:
					# Get body collider sizes for both structures
					var existing_collider_size: float = _get_body_collider_size(existing)
					var new_collider_size: float      = _get_body_collider_size(temp_structure)
					var min_dist: float               = (existing_collider_size + new_collider_size) / 2 + 5 # Small buffer
					if position.distance_to(existing.position) < min_dist:
						_show_placement_error("Cannot place overlapping ships!", position)
						temp_structure.queue_free()
						return null
			structure = temp_structure
		"LaserShip":
			var structure_scene: PackedScene = preload("res://structures/scenes/laser_ship.tscn")
			var temp_structure: Node         = structure_scene.instantiate()
			# Check for overlapping body colliders with other gunships/laserships on same orbit
			for existing in structures:
				if (existing is Gunship or existing is LaserShip) and existing.is_orbital and existing.orbit_idx == orbit_idx:
					# Get body collider sizes for both structures
					var existing_collider_size: float = _get_body_collider_size(existing)
					var new_collider_size: float      = _get_body_collider_size(temp_structure)
					var min_dist: float               = (existing_collider_size + new_collider_size) / 2 + 5 # Small buffer
					if position.distance_to(existing.position) < min_dist:
						_show_placement_error("Cannot place overlapping ships!", position)
						temp_structure.queue_free()
						return null
			structure = temp_structure
		"SlowArea":
			var slow_scene: PackedScene = preload("res://structures/scenes/slow_area.tscn")
			structure = slow_scene.instantiate()
			# Prevent overlapping slow area ranges
			for existing in structures:
				if existing is SlowArea and structure is SlowArea:
					var min_dist = existing.slow_range + structure.slow_range
					if position.distance_to(existing.position) < min_dist:
						_show_placement_error("Cannot place gravity wells in range of other gravity wells!", position)
						structure.queue_free()
						return null
		"ExplosiveMine":
			var mine_scene: PackedScene = preload("res://structures/scenes/explosive_mine.tscn")
			structure = mine_scene.instantiate()
			# Prevent overlapping mines
			for existing in structures:
				if existing is ExplosiveMine and structure is ExplosiveMine:
					var min_dist: int = 50  # Minimum distance between mines
					if position.distance_to(existing.position) < min_dist:
						_show_placement_error("Cannot place mines in range of other mines!", position)
						structure.queue_free()
						return null

	if structure:
		structure.position = position
		structure.is_orbital = is_orbital
		structure.orbit_idx = orbit_idx
		structures.append(structure)
		add_child(structure)
		return structure
	return null


# Helper function to get the size of a structure's body collider
func _get_body_collider_size(structure: Structure) -> float:
	if structure.has_node("BodyCollider"):
		var collider: Node = structure.get_node("BodyCollider")
		if collider.shape is CircleShape2D:
			return collider.shape.radius * 2
		elif collider.shape is RectangleShape2D:
			var rect_size = collider.shape.size
			return max(rect_size.x, rect_size.y)
	# Default fallback size
	return 40.0


# Show error message near mouse position
func _show_placement_error(message: String, position: Vector2) -> void:
	var error_label = Label.new()
	error_label.text = message
	error_label.modulate = Color.RED
	error_label.add_theme_font_size_override("font_size", 24)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Get mouse position from the viewport instead
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	error_label.position = mouse_pos + Vector2(20, -30)  # Offset so it doesn't cover the cursor
	error_label.z_index = 100  # Make sure it appears on top

	# Add to the scene (use UILayer if available, like the tooltip system)
	var ui_layer: Node = get_tree().current_scene.get_node_or_null("UILayer")
	if ui_layer:
		ui_layer.add_child(error_label)
	else:
		get_tree().current_scene.add_child(error_label)

	# Animate the label
	error_label.scale = Vector2.ZERO
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(error_label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(error_label, "modulate:a", 0.0, 1.5).set_delay(0.5)

	# Clean up after animation
	await tween.finished
	error_label.queue_free()


# called when structures are destroyed
func remove_structure(structure: Structure) -> void:
	print("Removing " + structure.name)
	if structure in structures:
		print("Removing " + structure.name)
		# Deactivate shield if structure had one
		if structure.has_method("deactivate_shield"):
			structure.deactivate_shield()
		structures.erase(structure)
		structure.queue_free()
	if structure.is_orbital:
		orbit_manager.remove_structure(structure)


# updates every structure in the scene
func update_all(delta: float) -> void:
	# Update shield timer
	if shield_active:
		shield_timer -= delta
		if shield_timer <= 0.0:
			_deactivate_shield()
	
	for structure in structures:
		if structure.has_method("update"):
			structure.update(delta)


func get_structure_cost(type: String) -> int:
	return structure_costs.get(type, 0)


func set_structure_cost(type: String, cost: int) -> void:
	structure_costs[type] = cost


func activate_shield():
	shield_active = true
	shield_timer = shield_duration
	
	# Activate shield visual for all orbital structures
	for structure in structures:
		if structure.is_orbital and structure.has_method("activate_shield"):
			structure.activate_shield()


func _deactivate_shield():
	shield_active = false
	shield_timer = 0.0
	
	# Deactivate shield visual for all orbital structures
	for structure in structures:
		if structure.is_orbital and structure.has_method("deactivate_shield"):
			structure.deactivate_shield()


func is_shield_active() -> bool:
	return shield_active


func get_shield_cost() -> int:
	return shield_cost


func increase_shield_cost():
	shield_cost += 10


func has_orbital_structures() -> bool:
	for structure in structures:
		if structure.is_orbital:
			return true
	return false
