extends Control

@onready var volume_slider: HSlider = $VolumeHbox/VolumeHslider

func _ready():
	# Initialize slider from saved settings
	volume_slider.value = Settings.master_volume
	# Apply saved volume immediately on startup
	AudioServer.set_bus_volume_db(0, linear_to_db(Settings.master_volume))
	# Connect signal
	volume_slider.value_changed.connect(_on_volume_changed)

func _on_volume_changed(value: float) -> void:
	Settings.master_volume = value
	Settings.save_settings()
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
