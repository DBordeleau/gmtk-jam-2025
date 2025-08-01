extends Control

@onready var main_menu_screen: Control = $MainMenuScene
@onready var how_to_play_screen: Control = $HowToPlayScreen
@onready var back_button: TextureButton = $BackButton
@onready var options_screen: Control = $OptionsScreen


func _on_how_to_play_button_pressed() -> void:
	main_menu_screen.visible = false 
	how_to_play_screen.visible = true
	back_button.visible = true

func _on_back_button_pressed() -> void:
	back_button.visible = false
	main_menu_screen.visible = true
	how_to_play_screen.visible = false
	options_screen.visible = false


func _on_options_button_pressed() -> void:
	main_menu_screen.visible = false 
	options_screen.visible = true
	back_button.visible = true
