## Singleton so we can load options on launch. Currently the only option we save is volume
extends Node

var master_volume: float = 1.0

const SETTINGS_PATH: String = "user://settings.cfg"

func _ready():
	load_settings()

func load_settings():
	var config = ConfigFile.new()
	var err = config.load(SETTINGS_PATH)
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", master_volume)

func save_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.save(SETTINGS_PATH)
