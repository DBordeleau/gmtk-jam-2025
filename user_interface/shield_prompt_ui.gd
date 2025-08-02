extends Control

@onready var cost_label: Label = null  # Will be set when we find the cost label node
@onready var tooltip_scene: PackedScene = preload("res://user_interface/shield_ui_tooltip.tscn")

var tooltip_instance: Control = null

func _ready():
	print("Shield prompt UI _ready() called")
	print("Shield prompt UI visible: ", visible)
	print("Shield prompt UI mouse_filter: ", mouse_filter)
	print("Shield prompt UI position: ", position)
	print("Shield prompt UI size: ", size)
	
	# Find the cost label in the scene tree
	# Adjust the path based on your actual UI structure
	cost_label = find_child("*CostLabel*", true, false)
	if not cost_label:
		cost_label = find_child("*Cost*", true, false)
	if not cost_label:
		# Try to find any Label node that might be the cost display
		var labels = find_children("", "Label", true, false)
		for label in labels:
			if "cost" in label.name.to_lower():
				cost_label = label
				break
	
	if not cost_label:
		print("Warning: Could not find cost label in shield prompt UI")
	
	# Ensure mouse filter is set to pass so we can receive mouse events
	mouse_filter = Control.MOUSE_FILTER_PASS
	print("Set mouse_filter to MOUSE_FILTER_PASS")
	
	# Connect mouse signals for tooltip
	mouse_entered.connect(_on_shield_prompt_mouse_entered)
	mouse_exited.connect(_on_shield_prompt_mouse_exited)
	print("Connected mouse signals for shield tooltip")

func _gui_input(event):
	if event is InputEventMouseMotion:
		print("Shield UI received mouse motion at: ", event.position)
	elif event is InputEventMouseButton:
		print("Shield UI received mouse button: ", event.button_index, " pressed: ", event.pressed)

func update_shield_cost(cost: int):
	if cost_label:
		cost_label.text = str(cost)
		print("Updated shield cost display to: ", cost)
	else:
		print("Warning: No cost label found to update")


func update_affordability(can_afford: bool):
	# Remove the alpha change - feedback label is sufficient
	pass


func _on_shield_prompt_mouse_entered():
	print("Hovered shield prompt UI")
	_show_shield_tooltip()


func _on_shield_prompt_mouse_exited():
	print("Mouse exited shield prompt UI")
	_hide_shield_tooltip()


func _show_shield_tooltip() -> void:
	print("Showing shield tooltip")
	_hide_shield_tooltip()
	
	tooltip_instance = tooltip_scene.instantiate()
	print("Instantiated shield tooltip scene:", tooltip_instance)
	if not tooltip_instance:
		print("Failed to instantiate shield tooltip scene!")
		return

	print("Adding tooltip to parent: ", get_parent())
	get_parent().add_child(tooltip_instance)
	tooltip_instance.z_index = 1000 # Ensure on top
	tooltip_instance.visible = true  # Explicitly set visible
	print("Shield tooltip added. Visible: ", tooltip_instance.visible, " Size: ", tooltip_instance.size)

	await get_tree().process_frame
	print("After process frame - Size: ", tooltip_instance.size)
	_update_tooltip_position()


func _hide_shield_tooltip():
	if tooltip_instance:
		print("Hiding shield tooltip.")
		tooltip_instance.queue_free()
		tooltip_instance = null


func _process(delta):
	if tooltip_instance:
		# Position to the right of the mouse cursor and above it
		var mouse_pos: Vector2 = get_global_mouse_position()
		var tooltip_size: Vector2 = tooltip_instance.size
		var new_position = mouse_pos + Vector2(20, (-tooltip_size.y / 2) - 100)  # 20px to the right, centered vertically, 200px above
		tooltip_instance.global_position = new_position
		print("Tooltip positioned at: ", new_position, " Mouse at: ", mouse_pos, " Tooltip size: ", tooltip_size)


func _update_tooltip_position():
	if tooltip_instance:
		# Position to the right of the mouse cursor
		var mouse_pos: Vector2 = get_global_mouse_position()
		var tooltip_size: Vector2 = tooltip_instance.size
		var new_position = mouse_pos + Vector2(20, (-tooltip_size.y / 2) - 100)  # 20px to the right, centered vertically
		tooltip_instance.global_position = new_position
		print("Initial tooltip positioned at: ", new_position, " Mouse at: ", mouse_pos, " Tooltip size: ", tooltip_size)
