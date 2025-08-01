## Control node that manages toggle buttons for placing structures
extends Control

signal structure_type_selected(type: String)
signal first_gunship_placed # tells the wave manager to start spawning the first wave

@export var structure_manager: StructureManager

# string for now but we should use something better so we can more easily access properties of the selected structure type
# like if it is orbital or not
var selected_structure_type: String = ""

# Every button should be added as an onready
# We can enable/show them as we unlock them if we want some structures to be locked initially
@onready var gunship_button: TextureButton = $GunshipButton
@onready var slow_area_button: TextureButton = $SlowAreaButton
@onready var laser_ship_button: TextureButton = $LaserShipButton

# player cant place a slow area until first placing a gunship
var slow_area_unlocked: bool = false

# AI generated tween stuff
@onready var tween: Tween = null
var is_visible_on_screen: bool = false

# when retrieving menu width dynamically it is being set as 0
# this is a temporary solution so we can modify the tween distance in one spot
var menu_width: int = 400

@onready var gunship_cost_label: Label = $GunshipButton/GunshipCostLabel
@onready var laser_ship_cost_label: Label = $LaserShipButton/LaserShipCostLabel

@onready var toggle_sfx: AudioStreamPlayer = $ToggleSFX

@onready var tooltip_scene = preload("res://user_interface/structure_tooltip.tscn")
var tooltip_instance: Control = null

# Sets the buttons to be in toggle mode, connects their signals, and makes them unpressed by default
# hides the slow area button by default until the player places a gunship
func _ready():
	var children = get_children()
	for child in children:
		if child is TextureButton:
			child.toggle_mode = true
			child.button_pressed = false

	gunship_button.pressed.connect(_on_gunship_button_pressed)
	slow_area_button.pressed.connect(_on_slow_area_button_pressed)
	laser_ship_button.pressed.connect(_on_laser_ship_button_pressed)
	gunship_button.mouse_entered.connect(_on_gunship_button_mouse_entered)
	gunship_button.mouse_exited.connect(_on_structure_button_mouse_exited)
	slow_area_button.mouse_entered.connect(_on_slow_area_button_mouse_entered)
	slow_area_button.mouse_exited.connect(_on_structure_button_mouse_exited)
	laser_ship_button.mouse_entered.connect(_on_laser_ship_button_mouse_entered)
	laser_ship_button.mouse_exited.connect(_on_structure_button_mouse_exited)

	slow_area_button.visible = false # Hide by default
	laser_ship_button.visible = false # Hide by default
	await get_tree().process_frame
	_update_menu_position(true)

# Every pressed function should set the selected struct type and disable all other buttons
func _on_gunship_button_pressed():
	if gunship_button.button_pressed:
		selected_structure_type = "Gunship"
		slow_area_button.button_pressed = false
		laser_ship_button.button_pressed = false
		structure_type_selected.emit("Gunship")
	else:
		selected_structure_type = ""
		gunship_button.button_pressed = false
		structure_type_selected.emit("")
		

func _on_slow_area_button_pressed():
	if slow_area_button.button_pressed:
		selected_structure_type = "SlowArea"
		gunship_button.button_pressed = false
		laser_ship_button.button_pressed = false
		structure_type_selected.emit("SlowArea")
	else:
		selected_structure_type = ""
		slow_area_button.button_pressed = false
		structure_type_selected.emit("")
		
func _on_laser_ship_button_pressed():
	if laser_ship_button.button_pressed:
		selected_structure_type = "LaserShip"
		gunship_button.button_pressed = false
		slow_area_button.button_pressed = false
		structure_type_selected.emit("LaserShip")
	else:
		selected_structure_type = ""
		laser_ship_button.button_pressed = false
		structure_type_selected.emit("")
		
# disables buttons if we cant afford associated structure
func update_buttons(currency: int):
	var gunship_cost = structure_manager.get_structure_cost("Gunship")
	var slow_area_cost = structure_manager.get_structure_cost("SlowArea")
	var laser_ship_cost = structure_manager.get_structure_cost("LaserShip")
	gunship_button.disabled = currency < gunship_cost
	if gunship_button.disabled:
		selected_structure_type = ""
	slow_area_button.disabled = currency < slow_area_cost
	if slow_area_button.disabled:
		selected_structure_type = ""
	laser_ship_button.disabled = currency < laser_ship_cost
	if laser_ship_button.disabled:
		selected_structure_type = ""

# called when a gunship is placed for the first time
func unlock_slow_area():
	slow_area_button.visible = true
	laser_ship_button.visible = true
	slow_area_unlocked = true
	first_gunship_placed.emit()
	
func _update_menu_position(off_screen: bool):
	var viewport_size = get_viewport().get_visible_rect().size
	
	if off_screen:
		# Position completely off the right edge
		position = Vector2(viewport_size.x, 50) # Set a reasonable Y position
		print("Menu positioned off-screen at: ", position)
	else:
		# Position on-screen with some padding from the right edge
		position = Vector2(viewport_size.x - menu_width - 10, 50) # 10px padding, 50px from top
		print("Menu positioned on-screen at: ", position)

func animate_menu_in():
	print("Starting animate_menu_in")
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Kill existing tween
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	var target_position = Vector2(viewport_size.x - menu_width - 10, position.y) # 10px padding
	
	print("Animating from: ", position, " to: ", target_position)
	
	tween.tween_property(self, "position", target_position, 0.4)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	is_visible_on_screen = true

func animate_menu_out():
	print("Starting animate_menu_out")
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Kill existing tween
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	var target_position = Vector2(viewport_size.x, position.y) # Completely off-screen
	
	print("Animating from: ", position, " to: ", target_position)
	
	tween.tween_property(self, "position", target_position, 0.4)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	
	is_visible_on_screen = false

func toggle_menu():
	print("Toggle menu called. Currently visible: ", is_visible_on_screen)
	toggle_sfx.play()
	if is_visible_on_screen:
		print("Animating menu off screen")
		animate_menu_out()
	else:
		print("Animating menu into screen")
		animate_menu_in()

# Call this function when the camera zooms to update menu position
func update_for_camera_zoom():
	if is_visible_on_screen:
		# Update position immediately if menu is currently visible
		var viewport_size = get_viewport().get_visible_rect().size
		var menu_width = size.x
		position = Vector2(viewport_size.x - menu_width - 10, position.y)
	# If menu is off-screen, it will be positioned correctly when animated in

# called by GameManager to deselect all buttons
func unpress_buttons():
	gunship_button.button_pressed = false
	laser_ship_button.button_pressed = false
	slow_area_button.button_pressed = false

func _on_gunship_button_mouse_entered():
	print("Hovered Gunship button")
	_show_structure_tooltip("Gunship")
	
func _on_slow_area_button_mouse_entered():
	print("Hovered SlowArea button")
	_show_structure_tooltip("SlowArea")
	
func _on_laser_ship_button_mouse_entered():
	print("Hovered LaserShip button")
	_show_structure_tooltip("LaserShip")
	
func _on_structure_button_mouse_exited():
	print("Mouse exited structure button")
	_hide_structure_tooltip()
	
func _show_structure_tooltip(type: String):
	print("Attempting to show tooltip for type:", type)
	_hide_structure_tooltip()
	var structure_scene = structure_manager.structure_map.get(type)
	if not structure_scene:
		print("No structure scene found for type:", type)
		return
	var structure = structure_scene.instantiate()
	print("Instantiated structure for tooltip:", structure)
	var name_text = structure.tooltip_name
	var desc_text = structure.tooltip_desc
	print("Tooltip name:", name_text, "Tooltip desc:", desc_text)

	tooltip_instance = tooltip_scene.instantiate()
	print("Instantiated tooltip scene:", tooltip_instance)
	if not tooltip_instance:
		print("Failed to instantiate tooltip scene!")
		return

	if not tooltip_instance.has_node("name_label") or not tooltip_instance.has_node("description_label"):
		print("Tooltip instance missing expected label nodes!")
	else:
		print("Tooltip instance has expected label nodes.")

	tooltip_instance.get_node("TextureRect/NameLabel").text = name_text
	tooltip_instance.get_node("TextureRect/DescriptionLabel").text = desc_text
	tooltip_instance.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tooltip_instance.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	# Dynamically resize font to fit label
	tooltip_instance.get_node("TextureRect/NameLabel").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_instance.get_node("TextureRect/DescriptionLabel").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	get_parent().add_child(tooltip_instance)
	tooltip_instance.z_index = 1000 # Ensure on top
	print("Tooltip added to menu.")
	await get_tree().process_frame
	_update_tooltip_position()

func _hide_structure_tooltip():
	if tooltip_instance:
		print("Hiding tooltip.")
		tooltip_instance.queue_free()
		tooltip_instance = null

func _process(delta):
	if tooltip_instance:
		var mouse_pos = get_global_mouse_position()
		var tooltip_size = tooltip_instance.size
		tooltip_instance.global_position = mouse_pos - Vector2(tooltip_size.x + 100, 1)

func _update_tooltip_position():
	if tooltip_instance:
		var mouse_pos = get_global_mouse_position()
		var tooltip_size = tooltip_instance.size
		tooltip_instance.global_position = mouse_pos - Vector2(tooltip_size.x + 100, 1)

func clear_selection():
	selected_structure_type = ""
	unpress_buttons()
