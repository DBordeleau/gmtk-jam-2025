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
	#gunship_button.button_pressed = true
	#structure_type_selected.emit("Gunship")

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
