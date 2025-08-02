extends Control

@onready var fade_rect: ColorRect = $FadeRect
@onready var hiscore_label: RichTextLabel = $HiscoreLabel

func _ready():
	_setup_hiscore_label()

func _setup_hiscore_label():
	# Load the hiscore using the same method as GameManager
	var hiscore = load_hiscore()
	
	# Set the text with BBCode formatting using teal colors to match your UI
	hiscore_label.text = "[font_size=50][center][color=#40E0D0]Your personal record is [b]%d[/b] waves completed[/color][/center][/font_size]" % hiscore
	
	# Start the bouncing animation
	_animate_hiscore_label()

func _animate_hiscore_label():
	# Create bouncing animation with teal glow effect
	var scale_tween = create_tween()
	scale_tween.set_loops()
	
	# Scale up slightly (bounce effect)
	scale_tween.tween_property(hiscore_label, "scale", Vector2(1.1, 1.1), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Scale back down
	scale_tween.tween_property(hiscore_label, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var bounce_tween = create_tween()
	bounce_tween.set_loops()
	bounce_tween.tween_property(hiscore_label, "position:y", hiscore_label.position.y - 5, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bounce_tween.tween_property(hiscore_label, "position:y", hiscore_label.position.y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Add teal glow effect that matches your "HOW TO PLAY" text
	var glow_tween = create_tween()
	glow_tween.set_loops()
	glow_tween.tween_property(hiscore_label, "modulate", Color(0.8, 1.3, 1.2), 1.5).set_trans(Tween.TRANS_SINE)  # Bright teal glow
	glow_tween.tween_property(hiscore_label, "modulate", Color(1.0, 1.0, 1.0), 1.5).set_trans(Tween.TRANS_SINE)  # Back to normal

# Copy the hiscore loading function from GameManager
func load_hiscore() -> int:
	if FileAccess.file_exists("user://hiscore.save"):
		var save = FileAccess.open("user://hiscore.save", FileAccess.READ)
		var value = save.get_32()
		save.close()
		return value
	return 0

func _on_play_button_pressed() -> void:
	_fade_and_load_scene()

func _fade_and_load_scene():
	fade_rect.visible = true
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	await tween.finished
	get_tree().change_scene_to_file("res://game/scenes/test_scene.tscn")


func _on_how_to_play_button_pressed() -> void:
	pass # Replace with function body.


func _on_options_button_pressed() -> void:
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	get_tree().quit()
