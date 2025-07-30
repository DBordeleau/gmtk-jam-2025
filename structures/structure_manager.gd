## Manages all structures placed in the scene. Structures can be orbital (placed on the loop) or static (placed anywhere in scene and don't move) 
## Structure types:
# AttackStructures attack nearby enemies automatically
# SlowStructures slow nearby enemies automatically
class_name StructureManager
extends Node

var structures: Array = []

# Called by the GameManager if the user left clicks with a structure selected
# Adds the placed structure to the array, adds it to the structure group and then adds it to the scene
# returns the placed structure
func place_structure(type: String, position: Vector2, is_orbital: bool) -> Structure:
	var structure: Structure = null

	match type:
		"Gunship":
			var structure_scene = preload("res://structures/scenes/gunship.tscn")
			var temp_structure = structure_scene.instantiate()
			# Prevent overlapping gunships
			for existing in structures:
				if existing is Gunship and temp_structure is Gunship:
					var min_dist = existing.attack_range + temp_structure.attack_range
					if position.distance_to(existing.position) < min_dist:
						print("Cannot place Gunship: too close to another Gunship.")
						return
			structure = temp_structure
		"SlowArea":
			var slow_scene = preload("res://structures/scenes/slow_area.tscn")
			structure = slow_scene.instantiate()
			# Prevent stacking slow areas
			for existing in structures:
				if existing is SlowArea and structure is SlowArea:
					var min_dist = existing.slow_range + structure.slow_range
					if position.distance_to(existing.position) < min_dist:
						print("Cannot place SlowArea: too close to another SlowArea.")
						return

	if structure:
		structure.position = position
		structure.is_orbital = is_orbital
		structures.append(structure)
		add_child(structure)
		return structure
	return null

# called when structures are destroyed
func remove_structure(structure: Structure) -> void:
	if structure in structures:
		structures.erase(structure)
		structure.queue_free()

# updates every structure in the scene
func update_all(delta: float) -> void:
	for structure in structures:
		if structure.has_method("update"):
			structure.update(delta)
