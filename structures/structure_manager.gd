## Manages all structures placed in the scene. Structures can be orbital (placed on the loop) or static (placed anywhere in scene and don't move) 
## Structure types:
# AttackStructures attack nearby enemies automatically
# SlowStructures slow nearby enemies automatically
class_name StructureManager
extends Node

@export var orbit_manager: OrbitManager

var structures: Array = []

var structure_costs = {
	"Gunship": 20,
	"SlowArea": 5,
	"LaserShip": 0,
	"ExplosiveMine": 10,  # Add this line
}

var structure_map = {
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
			var structure_scene = preload("res://structures/scenes/gunship.tscn")
			var temp_structure = structure_scene.instantiate()
			# Prevent overlapping gunships
			for existing in structures:
				if existing is Gunship and temp_structure is Gunship and existing.is_orbital and existing.orbit_idx == orbit_idx:
					var min_dist = existing.attack_range + temp_structure.attack_range
					if position.distance_to(existing.position) < min_dist:
						print("Cannot place Gunship: too close to another Gunship on the same orbit.")
						return
			structure = temp_structure
		"LaserShip":
			var structure_scene = preload("res://structures/scenes/laser_ship.tscn")
			var temp_structure = structure_scene.instantiate()
			# Prevent overlapping laser ships
			for existing in structures:
				if existing is LaserShip and temp_structure is LaserShip and existing.is_orbital and existing.orbit_idx == orbit_idx:
					var min_dist = existing.attack_range + temp_structure.attack_range
					if position.distance_to(existing.position) < min_dist:
						print("Cannot place Gunship: too close to another Gunship on the same orbit.")
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
		"ExplosiveMine":  # Add this case
			var mine_scene = preload("res://structures/scenes/explosive_mine.tscn")
			structure = mine_scene.instantiate()
			# Prevent overlapping mines
			for existing in structures:
				if existing is ExplosiveMine and structure is ExplosiveMine:
					var min_dist = 50  # Minimum distance between mines
					if position.distance_to(existing.position) < min_dist:
						print("Cannot place ExplosiveMine: too close to another mine.")
						return

	if structure:
		structure.position = position
		structure.is_orbital = is_orbital
		structure.orbit_idx = orbit_idx
		structures.append(structure)
		add_child(structure)
		return structure
	return null

# called when structures are destroyed
func remove_structure(structure: Structure) -> void:
	print("Removing " + structure.name)
	if structure in structures:
		print("Removing " + structure.name)
		structures.erase(structure)
		structure.queue_free()
	if structure.is_orbital:
		orbit_manager.remove_structure(structure)

# updates every structure in the scene
func update_all(delta: float) -> void:
	for structure in structures:
		if structure.has_method("update"):
			structure.update(delta)

func get_structure_cost(type: String) -> int:
	return structure_costs.get(type, 0)

func set_structure_cost(type: String, cost: int) -> void:
	structure_costs[type] = cost
