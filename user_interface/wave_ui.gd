extends Control

@onready var wave_label: RichTextLabel = $WaveLabel
@onready var wave_manager: WaveManager = $"../../WaveManager"

var wave_index: int = 0
var countdown_timer: Timer = null
var next_wave_seconds: int = 10
var is_spawning: bool = true

# connects signals from wave_manager
# and planet death signal (we need to hide the wave UI when we are showing game over)
func _ready():
	wave_manager.wave_completed.connect(_on_wave_completed)
	wave_manager.connect("enemy_spawned", Callable(self, "_on_enemy_spawned"))
	wave_manager.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
	wave_manager.connect("wave_spawning_started", Callable(self, "_on_wave_spawning_started"))
	wave_manager.connect("wave_spawning_finished", Callable(self, "_on_wave_spawning_finished"))
	_update_wave_label_spawning()
	
	var planet = get_tree().get_root().get_node("Planet") # Adjust path if needed
	if planet:
		planet.planet_destroyed.connect(_on_planet_destroyed)
		
	show_start_message()
	
# display red spawning label until all enemies are spawned
func _on_wave_spawning_started():
	is_spawning = true
	reset_wave_label_size()
	wave_label.text = "[color=red]Wave %d - Spawning![/color]" % (wave_index + 1)

func _on_wave_spawning_finished():
	is_spawning = false
	_update_wave_label_enemies_remaining()

func _on_enemy_spawned():
	if not is_spawning:
		_update_wave_label_enemies_remaining()

func _on_enemy_killed():
	if not is_spawning:
		_update_wave_label_enemies_remaining()

# starts next wave countdown based on the wave's delay time
func _on_wave_completed():
	var next_delay = wave_manager.get_next_wave_delay()
	next_wave_seconds = int(next_delay)
	wave_label.text = "[color=green]Wave %d Completed! Next wave begins in %d seconds.[/color]" % [wave_index + 1, next_wave_seconds]
	_start_countdown()

# start the delay timer for the next wave
func _start_countdown():
	if countdown_timer:
		countdown_timer.stop()
	else:
		countdown_timer = Timer.new()
		countdown_timer.one_shot = false
		countdown_timer.wait_time = 1.0
		add_child(countdown_timer)
		countdown_timer.timeout.connect(_on_countdown_tick)
	countdown_timer.start()

# updates label in realtime to count down to next wave
func _on_countdown_tick():
	next_wave_seconds -= 1
	if next_wave_seconds > 0:
		wave_label.text = "[color=green]Wave %d Completed! Next wave begins in %d seconds.[/color]" % [wave_index + 1, next_wave_seconds]
	else:
		countdown_timer.stop()
		next_wave_seconds = 3
		wave_index += 1
		_update_wave_label_spawning()
			
# display remaining enemies once all have been spawned
func _update_wave_label_enemies_remaining():
	var remaining = wave_manager.active_enemies.size()
	wave_label.text = "[color=yellow]Wave %d - %d enemies remaining[/color]" % [wave_index + 1, remaining]

func _update_wave_label_spawning():
	wave_label.text = "[color=red]Wave %d - Spawning![/color]" % (wave_index + 1)

# hide the wave ui when the planet dies
func _on_planet_destroyed():
	wave_label.visible = false

func _on_test_scene_game_over() -> void:
	self.hide()

func show_start_message():
	wave_label.text = "[center][color=yellow]Press B to open the shop.\nPlace a Gunship to start the game![/color][/center]"
	wave_label.visible = true
	wave_label.add_theme_font_size_override("normal_font_size", 48)

# return label to smaller size once we are spawning waves
func reset_wave_label_size():
	wave_label.remove_theme_font_size_override("normal_font_size")
