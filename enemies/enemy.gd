## Base enemy class which all enemies inherit from
class_name Enemy
extends CharacterBody2D # needed for move_and_slide() and velocity but we can change this if performance becomes a problem

@export var health: int = 10
@export var damage: int = 10
@export var speed: float = 100.0
var slow_multiplier: float = 1.0  
var death_sfx: AudioStreamPlayer
var killed_by_player: bool = false

func _ready():
	# Add to "enemies" group for targeting
	add_to_group("enemies")
	var children = get_children()
	for child in children:
		if child.name == "DeathSFX":
			death_sfx = child

func _physics_process(delta: float) -> void:
	# Default movement logic (can be overridden)
	move_enemy(delta)

func move_enemy(delta: float) -> void:
	# Example: Move right (override in child classes for custom behavior)
	velocity = Vector2(speed, 0)
	move_and_slide()

func take_damage(amount: int) -> void:
	killed_by_player = true
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	if death_sfx:
		# Detach the audio player so it can finish playing
		death_sfx.get_parent().remove_child(death_sfx)
		get_tree().current_scene.add_child(death_sfx)
		death_sfx.play()
		# Optionally, queue_free the audio player after it finishes
		death_sfx.finished.connect(func(): death_sfx.queue_free())
	queue_free()

func set_speed(new_speed: float) -> void:
	speed = new_speed
	
func set_slow_multiplier(multiplier: float) -> void:
	slow_multiplier = multiplier
