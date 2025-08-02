extends Control

signal upgrade_chosen(upgrade: Upgrade)

@onready var card_container: HBoxContainer = $VBoxContainer/HBoxContainer
var upgrades: Array[Upgrade] = []

func _ready():
	# Set up full screen
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Add dark background
	var background = ColorRect.new()
	background.color = Color(0, 0, 0, 0.8)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0) # Move to back
	
	# Ensure the VBoxContainer is properly centered
	var vbox = $VBoxContainer
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -450  # Increased width to accommodate spacing
	vbox.offset_right = 450
	vbox.offset_top = -250   # Increased height for title
	vbox.offset_bottom = 250
	vbox.position.x += 25
	
	# Style the title label
	var title_label = $VBoxContainer/Title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.modulate = Color(0.6, 1.0, 0.8)  # Changed to match planet colors
	title_label.add_theme_constant_override("outline_size", 3)
	title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	
	card_container.add_theme_constant_override("separation", 40)  
	
	# Start invisible for animation
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)

func setup_upgrades(upgrade_list: Array[Upgrade]):
	upgrades = upgrade_list
	_create_upgrade_cards()
	_animate_in()

func _create_upgrade_cards():
	# Clear existing cards
	for child in card_container.get_children():
		child.queue_free()
		
	for i in range(upgrades.size()):
		var upgrade = upgrades[i]
		var card = _create_upgrade_card(upgrade, i)
		card_container.add_child(card)
		
		# Start cards slightly offset for staggered animation
		card.modulate.a = 0.0
		card.scale = Vector2(0.8, 0.8)
		card.position.y = 50

func _create_upgrade_card(upgrade: Upgrade, index: int) -> Control:
	# Use a Panel for styling, with an invisible Button overlay for clicks
	var card_container = Control.new()
	card_container.custom_minimum_size = Vector2(250, 300)
	
	# Create the visual panel
	var card = Panel.new()
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Create a custom StyleBox with planet-inspired colors
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.3, 0.35, 0.95)  # Deep teal background
	style_box.border_color = Color(0.2, 0.6, 0.7, 1.0)  # Cyan border
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	
	card.add_theme_stylebox_override("panel", style_box)
	card_container.add_child(card)
	
	# Create invisible button overlay for clicking
	var button = Button.new()
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.flat = true
	button.modulate = Color(1, 1, 1, 0)  # Completely transparent
	button.pressed.connect(_on_upgrade_button_pressed.bind(index))
	card_container.add_child(button)
	
	# Create the content container inside the panel
	var content = VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 15)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse events
	# Add padding inside the card
	content.offset_left = 20
	content.offset_right = -20
	content.offset_top = 20
	content.offset_bottom = -20
	card.add_child(content)
	
	# Title
	var title = Label.new()
	title.text = upgrade.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Enable word wrapping
	title.custom_minimum_size = Vector2(210, 0)  # Set width constraint for wrapping
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.7, 1.0, 0.8)  # Light green/cyan title
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse events
	content.add_child(title)
	
	# Description
	var description = Label.new()
	description.text = upgrade.description
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	description.add_theme_constant_override("outline_size", 1)
	description.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	description.modulate = Color(0.85, 0.95, 0.9)  # Light teal text
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let button handle mouse events
	content.add_child(description)
	
	# Add hover animation
	_setup_card_hover_animation(card_container, card, style_box)
	
	return card_container

func _setup_card_hover_animation(card_container: Control, card: Panel, original_style: StyleBoxFlat):
	var hover_style = original_style.duplicate()
	hover_style.bg_color = Color(0.15, 0.4, 0.45, 0.98)  # Brighter teal on hover
	hover_style.border_color = Color(0.3, 0.8, 0.9, 1.0)  # Bright cyan border
	
	var button = card_container.get_child(1)  # The invisible button overlay
	
	button.mouse_entered.connect(func():
		card.add_theme_stylebox_override("panel", hover_style)
		var tween = create_tween()
		tween.tween_property(card_container, "scale", Vector2(1.05, 1.05), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	)
	
	button.mouse_exited.connect(func():
		card.add_theme_stylebox_override("panel", original_style)
		var tween = create_tween()
		tween.tween_property(card_container, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	)

func _animate_in():
	# Animate the background fade in
	var background_tween = create_tween()
	background_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	background_tween.parallel().tween_property(self, "modulate:a", 1.0, 0.3)
	background_tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Animate cards in staggered
	await get_tree().create_timer(0.2).timeout
	
	for i in range(card_container.get_child_count()):
		var card = card_container.get_child(i)
		var card_tween = create_tween()
		card_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
		card_tween.parallel().tween_property(card, "modulate:a", 1.0, 0.3)
		card_tween.parallel().tween_property(card, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_tween.parallel().tween_property(card, "position:y", 0, 0.4).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		# Add a small delay between cards
		if i < card_container.get_child_count() - 1:
			await get_tree().create_timer(0.1).timeout

func _on_upgrade_button_pressed(index: int):
	# Animate out before selecting
	_animate_out()
	await get_tree().create_timer(0.3).timeout
	upgrade_chosen.emit(upgrades[index])

func _animate_out():
	var out_tween = create_tween()
	out_tween.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	out_tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	out_tween.parallel().tween_property(self, "scale", Vector2(0.9, 0.9), 0.3).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
