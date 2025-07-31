## Control node that manages toggle buttons for placing structures
extends Control

signal structure_type_selected(type: String)

# string for now but we should use something better so we can more easily access properties of the selected structure type
# like if it is orbital or not
var selected_structure_type: String = ""

# Every button should be added as an onready
# We can enable/show them as we unlock them if we want some structures to be locked initially
@onready var gunship_button: TextureButton = $GunshipButton
@onready var slow_area_button: TextureButton = $SlowAreaButton

# player cant place a slow area until first placing a gunship
var slow_area_unlocked: bool = false

# AI generated tween stuff
@onready var tween: Tween = null
var is_visible_on_screen: bool = false

# when retrieving menu width dynamically it is being set as 0
# this is a temporary solution so we can modify the tween distance in one spot
var menu_width: int = 400

# Sets the buttons to be in toggle mode, connects their signals, and makes them unpressed by default
# hides the slow area button by default until the player places a gunship
func _ready():
	var children = get_children()
	for child: TextureButton in children:
		child.toggle_mode = true
		child.button_pressed = false

	gunship_button.pressed.connect(_on_gunship_button_pressed)
	slow_area_button.pressed.connect(_on_slow_area_button_pressed)

	slow_area_button.visible = false # Hide by default
	await get_tree().process_frame
	_update_menu_position(true)

# Every pressed function should set the selected struct type and disable all other buttons
func _on_gunship_button_pressed():
	if gunship_button.button_pressed:
		selected_structure_type = "Gunship"
		slow_area_button.button_pressed = false
		structure_type_selected.emit("Gunship")
	else:
		selected_structure_type = ""
		structure_type_selected.emit("")
		

func _on_slow_area_button_pressed():
	if slow_area_button.button_pressed:
		selected_structure_type = "SlowArea"
		gunship_button.button_pressed = false
		structure_type_selected.emit("SlowArea")
	else:
		selected_structure_type = ""
		structure_type_selected.emit("")
		
# disables buttons if we cant afford associated structure
func update_buttons(currency: int):
	gunship_button.disabled = currency < 20
	slow_area_button.disabled = currency < 5

# called when a gunship is placed for the first time
func unlock_slow_area():
	slow_area_button.visible = true
	slow_area_unlocked = true

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
