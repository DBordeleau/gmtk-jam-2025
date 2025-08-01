extends Control

@onready var volume_hslider: HSlider = $VolumeHbox/VolumeHslider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

func _on_quit_button_pressed() -> void:
	pass # Replace with function body.


func _on_resume_button_pressed() -> void:
	pass # Replace with function body.
