class_name WaveManager
extends Node

signal start_first_wave
signal wave_completed
signal wave_spawning_started
signal wave_spawning_finished
signal enemy_spawned
signal enemy_killed
var spawn_interval: float = 0.5 # seconds between individual enemy spawns
var camera: Camera2D # camera reference so we can spawn enemies outside of view
# Difficulty scaling parameters
var base_wave_cost: int             = 6
var wave_cost_scaling_factor: float = 1.3
var base_wave_delay: float          = 5.0
var sequence_time_variance: float   = 2.0
# Enemy scene references for random generation
var enemy_scenes: Array[PackedScene] = []
var enemy_costs: Array[int]          = []
var current_wave_index: int          = 0
var active_enemies: Array            = []
var spawning: bool                   = false
var enemies_to_spawn: int            = 0
var enemies_spawned: int             = 0


func _ready() -> void:
	if enemy_scenes.is_empty():
		enemy_scenes.append(preload("res://enemies/scenes/asteroid.tscn"))
		enemy_scenes.append(preload("res://enemies/scenes/big_asteroid.tscn"))
		enemy_scenes.append(preload("res://enemies/scenes/comet.tscn"))
	if enemy_costs.size() != enemy_scenes.size():
		enemy_costs = [3, 6, 4]
	start_first_wave.connect(_on_start_first_wave)


func generate_wave(wave_number: int) -> Wave:
	var new_wave = Wave.new()

	# Calculate difficulty scaling using cost budget instead of enemy count
	var difficulty_multiplier: float = pow(wave_cost_scaling_factor, wave_number)
	var total_cost_budget: int       = int(base_wave_cost * difficulty_multiplier)

	# Determine number of enemy sequences (1-3 based on wave number)
	var num_sequences: int = 1 + int(wave_number / 3)

	# Create enemy sequences
	var sequences: Array[EnemySequence] = []
	var cost_per_sequence               = max(enemy_costs[0], int(total_cost_budget / num_sequences)) # Ensure at least one basic enemy per sequence
	var remaining_budget: int           = total_cost_budget

	# Choose random enemy type, with preference for stronger enemies in later waves
	var available_indices: Array[Variant] = [0] # Always include basic asteroid

	if wave_number >= 5:
		available_indices.append(2) # Add comet after wave 5

	if wave_number >= 10:
		available_indices.append(1) # Add big asteroid after wave 10

	for i in range(num_sequences):
		var sequence = EnemySequence.new()

		# Determine budget for this sequence
		var sequence_budget: int
		if i == num_sequences - 1:
			sequence_budget = remaining_budget # Give remaining budget to last sequence
		else:
			sequence_budget = min(cost_per_sequence, remaining_budget)

		# Choose enemy type that fits within budget
		var valid_enemies: Array[Variant] = []
		for idx in available_indices:
			if enemy_costs[idx] <= sequence_budget:
				valid_enemies.append(idx)

		# If no enemies fit the budget, use the cheapest available enemy
		if valid_enemies.is_empty():
			valid_enemies.append(0) # Fall back to basic asteroid

		var enemy_index = valid_enemies[randi() % valid_enemies.size()]
		sequence.enemy = enemy_scenes[enemy_index]

		# Calculate how many enemies we can afford with this budget
		var enemy_cost: int = enemy_costs[enemy_index]
		sequence.amount = max(1, int(sequence_budget / enemy_cost))

		# Deduct actual cost used from remaining budget
		var actual_cost_used = sequence.amount * enemy_cost
		remaining_budget -= actual_cost_used

		# Set spawn timing with some variance
		sequence.time = i * sequence_time_variance + randf() * sequence_time_variance

		sequences.append(sequence)

	new_wave.enemy_sequences = sequences
	new_wave.time_to_next_wave = base_wave_delay + randf() * 2.0 # Add some variance to wave timing

	return new_wave


# starts spawning the wave and emits a signal when complete
func start_wave(wave_index: int = 0) -> void:
	current_wave_index = wave_index

	var current_wave: Wave = generate_wave(current_wave_index)

	spawning = true
	active_enemies.clear()
	enemies_to_spawn = 0
	enemies_spawned = 0

	for sequence in current_wave.enemy_sequences:
		enemies_to_spawn += sequence.amount
	emit_signal("wave_spawning_started")
	await _spawn_wave(current_wave)
	emit_signal("wave_spawning_finished")


# spawns enemy sequences and emits a signal for each enemy spawned so the wave ui can count up in realtime
func _spawn_wave(wave: Wave) -> void:
	for sequence in wave.enemy_sequences:
		await safe_wait(sequence.time)
		for i in range(sequence.amount):
			await safe_wait(spawn_interval)
			var enemy_instance: Node = sequence.enemy.instantiate()
			var spawn_pos: Vector2   = get_random_edge_position()
			enemy_instance.global_position = spawn_pos
			add_child(enemy_instance)
			active_enemies.append(enemy_instance)
			enemies_spawned += 1
			emit_signal("enemy_spawned")
			enemy_instance.tree_exited.connect(_on_enemy_exited.bind(enemy_instance))


# helper function for spawning enemies around the edge of the screen
func get_random_edge_position() -> Vector2:
	if not get_tree():
		return Vector2.ZERO
	var camera_rect: Rect2 = get_camera_visible_rect()
	var edge: int          = randi() % 4
	var x: float           = 0.0
	var y: float           = 0.0
	match edge:
		0: # top
			x = randf_range(camera_rect.position.x, camera_rect.position.x + camera_rect.size.x)
			y = camera_rect.position.y - 50
		1: # bottom
			x = randf_range(camera_rect.position.x, camera_rect.position.x + camera_rect.size.x)
			y = camera_rect.position.y + camera_rect.size.y + 50
		2: # left
			x = camera_rect.position.x - 50
			y = randf_range(camera_rect.position.y, camera_rect.position.y + camera_rect.size.y)
		3: # right
			x = camera_rect.position.x + camera_rect.size.x + 50
			y = randf_range(camera_rect.position.y, camera_rect.position.y + camera_rect.size.y)
	return Vector2(x, y)


# helper function to calculate viewport edges after the camera has zoomed out
func get_camera_visible_rect() -> Rect2:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var camera_center: Vector2 = camera.get_screen_center_position()
	var zoom: Vector2          = camera.zoom

	# Calculate the visible area in world coordinates
	var visible_size: Vector2 = viewport_size / zoom
	var top_left: Vector2     = camera_center - visible_size / 2

	return Rect2(top_left, visible_size)


func _on_enemy_exited(enemy):
	if enemy in active_enemies:
		active_enemies.erase(enemy)
		if enemy.killed_by_player:
			emit_signal("enemy_killed")
	if spawning and active_enemies.is_empty() and enemies_spawned == enemies_to_spawn:
		spawning = false
		emit_signal("wave_completed")


# getter function for wave_ui
func get_next_wave_delay() -> float:
	# Generate next wave to get its delay time
	var next_wave: Wave = generate_wave(current_wave_index)
	return next_wave.time_to_next_wave


func safe_wait(time: float) -> void:
	if not get_tree() or not is_inside_tree():
		return
	await get_tree().create_timer(time).timeout


func remove_all_active_enemies() -> void:
	for enemy in active_enemies:
		enemy.queue_free()


func _on_start_first_wave():
	start_wave(0)
