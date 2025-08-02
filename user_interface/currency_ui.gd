extends Control

@onready var currency_label: Label = $CurrencyCount


func update_currency(new_amount: int, change: int = 0):
	currency_label.text = str(new_amount)

	if change != 0:
		_show_currency_change(change)


func _show_currency_change(change: int):
	# Create the change label
	var change_label = Label.new()
	change_label.text = ("+" if change > 0 else "") + str(change)
	change_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	change_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	change_label.add_theme_font_size_override("font_size", 18)
	change_label.add_theme_constant_override("outline_size", 2)
	change_label.add_theme_color_override("font_outline_color", Color.BLACK)

	# Set colors based on gain/loss
	if change > 0:
		change_label.modulate = Color(0.3, 1.0, 0.3)  # Green for gains
	else:
		change_label.modulate = Color(1.0, 0.3, 0.3)  # Red for losses

	# Position it near the currency label
	change_label.position = currency_label.position + Vector2(currency_label.size.x + 10, 0)
	change_label.z_index = 100

	add_child(change_label)

	# Animate the change label
	_animate_currency_change(change_label, change > 0)


func _animate_currency_change(label: Label, is_gain: bool):
	# Start small and transparent
	label.scale = Vector2(0.5, 0.5)
	label.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)

	# Scale up and fade in
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 1.0, 0.2)

	# Move upward (gains) or downward (losses)
	var move_direction = Vector2(0, -30) if is_gain else Vector2(0, 30)
	tween.tween_property(label, "position", label.position + move_direction, 0.8).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	# Hold for a moment, then fade out
	tween.tween_property(label, "modulate:a", 0.0, 0.3).set_delay(0.5)
	tween.tween_property(label, "scale", Vector2(0.8, 0.8), 0.3).set_delay(0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)

	# Clean up
	await tween.finished
	label.queue_free()


# Add a pulse animation to the main currency label
func _pulse_currency_label():
	var tween = create_tween()
	tween.tween_property(currency_label, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(currency_label, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
