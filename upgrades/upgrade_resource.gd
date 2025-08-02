class_name Upgrade
extends Resource

@export var name: String
@export var description: String
@export var target_structure_type: String # "Gunship", "LaserShip", "SlowArea", etc.
@export var property_name: String # "attack_cooldown", "speed", etc.
@export var modification_type: String # "add", "multiply", "set"
@export var value: float


func apply_to_structure(structure: Structure) -> void:
	if not structure.has_method("get") or not structure.has_method("set"):
		return

	var current_value = structure.get(property_name)
	if current_value == null:
		return

	var new_value: float
	match modification_type:
		"add":
			new_value = current_value + value
		"multiply":
			new_value = current_value * value
		"set":
			new_value = value

	# Clamp attack_cooldown to minimum of 0.1
	# we should also make it so we cant spawn the upgrade that lowers attack cooldown now
	if property_name == "attack_cooldown":
		new_value = max(new_value, 0.1)

	structure.set(property_name, new_value)
