extends Control

@onready var fade_rect: ColorRect = $FadeRect

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
