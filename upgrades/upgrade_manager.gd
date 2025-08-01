class_name UpgradeManager
extends Node

signal upgrade_selected
signal upgrade_choice_started
signal upgrade_choice_finished

var available_upgrades: Array[Upgrade] = []
var applied_upgrades: Array[Upgrade] = []

@onready var upgrade_ui: Control = null

func _ready():
	_initialize_upgrades()

func _initialize_upgrades():
	# Gunship upgrades
	var cannon_cooling = Upgrade.new()
	cannon_cooling.name = "Cannon Cooling Tech"
	cannon_cooling.description = "Reduce Gunship attack cooldown by 0.1 seconds"
	cannon_cooling.target_structure_type = "Gunship"
	cannon_cooling.property_name = "attack_cooldown"
	cannon_cooling.modification_type = "add"
	cannon_cooling.value = -0.1
	
	var improved_propulsion = Upgrade.new()
	improved_propulsion.name = "Improved Propulsion System"
	improved_propulsion.description = "Increase Gunship orbiting speed by 10%"
	improved_propulsion.target_structure_type = "Gunship"
	improved_propulsion.property_name = "speed"
	improved_propulsion.modification_type = "multiply"
	improved_propulsion.value = 1.1
	
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
	siege_cannons.description = "Increase Gunship attack range by 10"
	siege_cannons.target_structure_type = "Gunship"
	siege_cannons.property_name = "attack_range"
	siege_cannons.modification_type = "add"
	siege_cannons.value = 10.0
	
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
	supercharged_beams.description = "Reduce Laser Ship attack cooldown by 0.1 seconds"
	supercharged_beams.target_structure_type = "LaserShip"
	supercharged_beams.property_name = "attack_cooldown"
	supercharged_beams.modification_type = "add"
	supercharged_beams.value = -0.1
	
	var lightweight_laser_ships = Upgrade.new()
	lightweight_laser_ships.name = "Lightweight Laser Ships"
	lightweight_laser_ships.description = "Increase Laser Ship orbiting speed by 10%"
	lightweight_laser_ships.target_structure_type = "LaserShip"
	lightweight_laser_ships.property_name = "speed"
	lightweight_laser_ships.modification_type = "multiply"
	lightweight_laser_ships.value = 1.1
	
	# SlowArea upgrades
	var black_hole_friday = Upgrade.new()
	black_hole_friday.name = "Black Hole Friday"
	black_hole_friday.description = "Halve the current cost of Gravity Wells"
	black_hole_friday.target_structure_type = "SlowArea"
	black_hole_friday.property_name = "cost_reduction"
	black_hole_friday.modification_type = "multiply"
	black_hole_friday.value = 0.5
	
	available_upgrades = [
		cannon_cooling, 
		improved_propulsion, 
		gunship_sale, 
		siege_cannons,
		laser_ship_sale, 
		supercharged_beams, 
		lightweight_laser_ships,
		black_hole_friday
	]

func start_upgrade_choice():
	upgrade_choice_started.emit()
	var chosen_upgrades = _get_random_upgrades(3)
	_show_upgrade_ui(chosen_upgrades)

func _get_random_upgrades(count: int) -> Array[Upgrade]:
	var shuffled = available_upgrades.duplicate()
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
		var current_cost = structure_manager.get_structure_cost(upgrade.target_structure_type)
		var new_cost = int(current_cost * upgrade.value)
		structure_manager.set_structure_cost(upgrade.target_structure_type, new_cost)
		
		# Update UI label
		var game_manager = get_tree().get_root().get_node("GameManager")
		if upgrade.target_structure_type == "Gunship":
			game_manager._update_gunship_cost_label(new_cost)
		elif upgrade.target_structure_type == "LaserShip":
			game_manager._update_lasership_cost_label(new_cost)
		return
	
	# Apply to existing structures
	var structure_manager = get_tree().get_root().get_node("GameManager/StructureManager")
	for structure in structure_manager.structures:
		if structure.get_script() and structure.get_script().get_global_name() == upgrade.target_structure_type:
			upgrade.apply_to_structure(structure)
			
			# update range display if attack_range was modified
			if upgrade.property_name == "attack_range" and structure.has_method("update_range_display"):
				structure.update_range_display()

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
