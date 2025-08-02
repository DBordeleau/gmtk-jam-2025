class_name UpgradeManager
extends Node

signal upgrade_selected
signal upgrade_choice_started
signal upgrade_choice_finished
var available_upgrades: Array[Upgrade] = []
var applied_upgrades: Array[Upgrade]   = []

@onready var upgrade_ui: Control = null


#@export var structure_manager: StructureManager

func _ready():
	_initialize_upgrades()


func _initialize_upgrades():
	# Gunship upgrades
	var cannon_cooling = Upgrade.new()
	cannon_cooling.name = "Cannon Cooling Tech"
	cannon_cooling.description = "Reduce Gunship attack cooldown by 0.2 seconds"
	cannon_cooling.target_structure_type = "Gunship"
	cannon_cooling.property_name = "attack_cooldown"
	cannon_cooling.modification_type = "add"
	cannon_cooling.value = -0.2

	var improved_propulsion = Upgrade.new()
	improved_propulsion.name = "Improved Propulsion System"
	improved_propulsion.description = "Increase Gunship orbiting speed by 20%"
	improved_propulsion.target_structure_type = "Gunship"
	improved_propulsion.property_name = "speed"
	improved_propulsion.modification_type = "multiply"
	improved_propulsion.value = 1.2

	var gunship_sale = Upgrade.new()
	gunship_sale.name = "Gunship Sale"
	gunship_sale.description = "Halve the current cost of Gunships"
	gunship_sale.target_structure_type = "Gunship"
	gunship_sale.property_name = "cost_reduction"
	gunship_sale.modification_type = "multiply"
	gunship_sale.value = 0.5

	# Siege Cannons upgrade
	var siege_cannons = Upgrade.new()
	siege_cannons.name = "Siege Cannons"
	siege_cannons.description = "Increase Gunship attack range by 15"
	siege_cannons.target_structure_type = "Gunship"
	siege_cannons.property_name = "attack_range"
	siege_cannons.modification_type = "add"
	siege_cannons.value = 15.0

	# LaserShip upgrades
	var laser_ship_sale = Upgrade.new()
	laser_ship_sale.name = "Laser Ship Sale"
	laser_ship_sale.description = "Halve the current cost of Laser Ships"
	laser_ship_sale.target_structure_type = "LaserShip"
	laser_ship_sale.property_name = "cost_reduction"
	laser_ship_sale.modification_type = "multiply"
	laser_ship_sale.value = 0.5

	var supercharged_beams = Upgrade.new()
	supercharged_beams.name = "Supercharged Beams"
	supercharged_beams.description = "Reduce Laser Ship attack cooldown by 0.2 seconds"
	supercharged_beams.target_structure_type = "LaserShip"
	supercharged_beams.property_name = "attack_cooldown"
	supercharged_beams.modification_type = "add"
	supercharged_beams.value = -0.2

	var lightweight_laser_ships = Upgrade.new()
	lightweight_laser_ships.name = "Lightweight Laser Ships"
	lightweight_laser_ships.description = "Increase Laser Ship orbiting speed by 20%"
	lightweight_laser_ships.target_structure_type = "LaserShip"
	lightweight_laser_ships.property_name = "speed"
	lightweight_laser_ships.modification_type = "multiply"
	lightweight_laser_ships.value = 1.2

	# SlowArea upgrades
	var black_hole_friday = Upgrade.new()
	black_hole_friday.name = "Black Hole Friday"
	black_hole_friday.description = "Halve the current cost of Gravity Wells"
	black_hole_friday.target_structure_type = "SlowArea"
	black_hole_friday.property_name = "cost_reduction"
	black_hole_friday.modification_type = "multiply"
	black_hole_friday.value = 0.5

	var deeper_black_holes = Upgrade.new()
	deeper_black_holes.name = "Deeper Black Holes"
	deeper_black_holes.description = "Increase the range of gravity wells by 15"
	deeper_black_holes.target_structure_type = "SlowArea"
	deeper_black_holes.property_name = "slow_range"
	deeper_black_holes.modification_type = "add"
	deeper_black_holes.value = 15.0

	# Explosive Mine Upgrades
	var bigger_bombs = Upgrade.new()
	bigger_bombs.name = "Bigger Bombs"
	bigger_bombs.description = "Increase the explosion radius of explosive mines by 15"
	bigger_bombs.target_structure_type = "ExplosiveMine"
	bigger_bombs.property_name = "explosion_range"
	bigger_bombs.modification_type = "add"
	bigger_bombs.value = 15.0

	var explosive_savings = Upgrade.new()
	explosive_savings.name = "Explosive Savings"
	explosive_savings.description = "Halve the cost of explosive mines"
	explosive_savings.target_structure_type = "ExplosiveMine"
	explosive_savings.property_name = "cost_reduction"
	explosive_savings.modification_type = "multiply"
	explosive_savings.value = 0.5

	# Special Upgrades
	var compound_interest = Upgrade.new()
	compound_interest.name = "Compound Interest"
	compound_interest.description = "Earn an extra +1 currency whenever you eliminate an enemy"
	compound_interest.target_structure_type = "Global"  # Special type for global effects
	compound_interest.property_name = "enemy_kill_bonus"
	compound_interest.modification_type = "add"
	compound_interest.value = 1

	available_upgrades = [
	cannon_cooling,
	improved_propulsion,
	gunship_sale,
	siege_cannons,
	laser_ship_sale,
	supercharged_beams,
	lightweight_laser_ships,
	black_hole_friday,
	bigger_bombs,
	compound_interest,
	deeper_black_holes,
	explosive_savings
	]


func start_upgrade_choice():
	upgrade_choice_started.emit()
	var chosen_upgrades = _get_random_upgrades(3)
	_show_upgrade_ui(chosen_upgrades)


func _get_random_upgrades(count: int) -> Array[Upgrade]:
	var filtered: Array[Upgrade] = []
	for upgrade in available_upgrades:
		if _should_offer_upgrade(upgrade):
			filtered.append(upgrade)
	var shuffled = filtered.duplicate()
	shuffled.shuffle()
	return shuffled.slice(0, min(count, shuffled.size()))


func _show_upgrade_ui(upgrades: Array[Upgrade]):
	upgrade_ui = preload("res://upgrades/upgrade_choice_ui.tscn").instantiate()
	# Add to UILayer instead of current_scene
	var ui_layer = get_tree().get_root().get_node("GameManager/UILayer")
	ui_layer.add_child(upgrade_ui)
	upgrade_ui.setup_upgrades(upgrades)
	upgrade_ui.upgrade_chosen.connect(_on_upgrade_chosen)


func _on_upgrade_chosen(upgrade: Upgrade):
	apply_upgrade(upgrade)
	applied_upgrades.append(upgrade)
	_hide_upgrade_ui()
	upgrade_choice_finished.emit()


func apply_upgrade(upgrade: Upgrade):
	# Handle special case for cost reduction
	if upgrade.property_name == "cost_reduction":
		var structure_manager = get_tree().get_root().get_node("GameManager/StructureManager")
		var current_cost      = structure_manager.get_structure_cost(upgrade.target_structure_type)
		var new_cost          = int(current_cost * upgrade.value)
		structure_manager.set_structure_cost(upgrade.target_structure_type, new_cost)

		# Update UI label
		var game_manager = get_tree().get_root().get_node("GameManager")
		if upgrade.target_structure_type == "Gunship":
			game_manager._update_gunship_cost_label(new_cost)
		elif upgrade.target_structure_type == "LaserShip":
			game_manager._update_lasership_cost_label(new_cost)
		elif upgrade.target_structure_type == "SlowArea":
			game_manager._update_slowarea_cost_label(new_cost)
		elif upgrade.target_structure_type == "ExplosiveMine":
			game_manager._update_explosive_mine_cost_label(new_cost)

		game_manager.structure_menu.update_buttons(game_manager.currency)
		return

	# Handle global upgrades (like Compound Interest)
	if upgrade.target_structure_type == "Global":
		# Global upgrades are tracked in applied_upgrades and handled elsewhere
		return

	# Apply to existing structures
	var structure_manager = get_tree().get_root().get_node("GameManager/StructureManager")
	var orbit_manager     = get_tree().get_root().get_node("GameManager/OrbitManager")

	for structure in structure_manager.structures:
		if structure.get_script() and structure.get_script().get_global_name() == upgrade.target_structure_type:
			upgrade.apply_to_structure(structure)
			if structure.has_method("update_tooltip_desc"):
				structure.update_tooltip_desc()

			# UPDATE ORBIT MANAGER FOR SPEED CHANGES
			if upgrade.property_name == "speed" and structure.is_orbital:
				orbit_manager.update_structure_speed(structure, structure.speed)

			# update range display if attack_range was modified
			if upgrade.property_name == "attack_range" and structure.has_method("update_range_display"):
				structure.update_range_display()

			# Update range collider for SlowArea range changes
			if upgrade.property_name == "slow_range" and structure.has_node("RangeArea/RangeCollider"):
				var collider = structure.get_node("RangeArea/RangeCollider")
				if collider.shape is CircleShape2D:
					collider.shape.radius = structure.slow_range

			# Update range collider for ExplosiveMine explosion range changes
			if upgrade.property_name == "explosion_range" and structure.has_node("RangeArea/RangeCollider"):
				var collider = structure.get_node("RangeArea/RangeCollider")
				if collider.shape is CircleShape2D:
					collider.shape.radius = structure.explosion_range


func _hide_upgrade_ui():
	if upgrade_ui:
		upgrade_ui.queue_free()
		upgrade_ui = null


# Call this when a new structure is placed to apply all relevant upgrades
func apply_upgrades_to_new_structure(structure: Structure):
	var structure_type = structure.get_script().get_global_name() if structure.get_script() else ""
	for upgrade in applied_upgrades:
		if upgrade.target_structure_type == structure_type and upgrade.property_name != "cost_reduction":
			upgrade.apply_to_structure(structure)
	if structure.has_method("update_tooltip_desc"):
		structure.update_tooltip_desc()


func has_global_upgrade(property_name: String) -> bool:
	for upgrade in applied_upgrades:
		if upgrade.target_structure_type == "Global" and upgrade.property_name == property_name:
			return true
	return false


func get_global_upgrade_value(property_name: String) -> float:
	for upgrade in applied_upgrades:
		if upgrade.target_structure_type == "Global" and upgrade.property_name == property_name:
			return upgrade.value
	return 0.0

func _should_offer_upgrade(upgrade: Upgrade) -> bool:
	# Prevent Cannon Cooling Tech if Gunship cooldown is already 0.2 or less
	if upgrade.property_name == "attack_cooldown" and upgrade.target_structure_type == "Gunship":
		var structure_scene = get_tree().get_root().get_node("GameManager/StructureManager").structure_map.get("Gunship")
		if structure_scene:
			var temp = structure_scene.instantiate()
			apply_upgrades_to_new_structure(temp)
			if temp.attack_cooldown <= 0.2:
				temp.queue_free()
				return false
			temp.queue_free()
	# Prevent Supercharged Beams if LaserShip cooldown is already 0.2 or less
	if upgrade.property_name == "attack_cooldown" and upgrade.target_structure_type == "LaserShip":
		var structure_scene = get_tree().get_root().get_node("GameManager/StructureManager").structure_map.get("LaserShip")
		if structure_scene:
			var temp = structure_scene.instantiate()
			apply_upgrades_to_new_structure(temp)
			if temp.attack_cooldown <= 0.2:
				temp.queue_free()
				return false
			temp.queue_free()
	return true
