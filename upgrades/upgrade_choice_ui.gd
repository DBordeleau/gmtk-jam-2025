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
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER_LEFT)
	vbox.anchor_left = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -400  # Half of estimated width
	vbox.offset_right = 400
	vbox.offset_top = -200   # Half of estimated height
	vbox.offset_bottom = 200
	
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
	var card = VBoxContainer.new()
	card.custom_minimum_size = Vector2(250, 300)
	card.add_theme_constant_override("separation", 10)
	
	# Card background with border effect
	var background = ColorRect.new()
	background.color = Color(0.2, 0.2, 0.3, 0.9)
	background.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	background.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(background)
	
	# Add a subtle border
	var border = ColorRect.new()
	border.color = Color(0.4, 0.4, 0.5, 1.0)
	border.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	border.size_flags_vertical = Control.SIZE_EXPAND_FILL
	border.custom_minimum_size = Vector2(252, 302)
	card.add_child(border)
	card.move_child(border, 0)  # Move behind background
	
	# Title
	var title = Label.new()
	title.text = upgrade.name
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("normal_font_size", 18)
	title.modulate = Color(1, 0.8, 0) # Golden color
	title.add_theme_constant_override("outline_size", 2)
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	card.add_child(title)
	
	# Description
	var description = Label.new()
	description.text = upgrade.description
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.y = 100
	description.add_theme_constant_override("outline_size", 1)
	description.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	card.add_child(description)
	
	# Select button
	var button = Button.new()
	button.text = "Select"
	button.custom_minimum_size = Vector2(100, 40)
	button.add_theme_font_size_override("font_size", 16)
	button.pressed.connect(_on_upgrade_button_pressed.bind(index))
	card.add_child(button)
	
	return card

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
