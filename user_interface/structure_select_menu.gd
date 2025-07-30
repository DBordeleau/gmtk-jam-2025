## Control node that manages toggle buttons for placing structures
extends Control

# string for now but we should use something better so we can more easily access properties of the selected structure type
# like if it is orbital or not
var selected_structure_type: String = ""

# Every button should be added as an onready
# We can enable/show them as we unlock them if we want some structures to be locked initially
@onready var gunship_button: TextureButton = $GunshipButton
@onready var slow_area_button: TextureButton = $SlowAreaButton

# Sets the buttons to be in toggle mode, connects their signals, and makes them unpressed by default
func _ready():
	var children = get_children()
	for child: TextureButton in children:
		child.toggle_mode = true
		child.button_pressed = false

	gunship_button.pressed.connect(_on_gunship_button_pressed)
	slow_area_button.pressed.connect(_on_slow_area_button_pressed)

# Every pressed function should set the selected struct type and disable all other buttons
func _on_gunship_button_pressed():
	if gunship_button.button_pressed:
		selected_structure_type = "Gunship"
		slow_area_button.button_pressed = false
	else:
		selected_structure_type = ""

func _on_slow_area_button_pressed():
	if slow_area_button.button_pressed:
		selected_structure_type = "SlowArea"
		gunship_button.button_pressed = false
	else:
		selected_structure_type = ""
