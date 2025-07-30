## Base enemy class which all enemies inherit from
class_name Enemy
extends CharacterBody2D # needed for move_and_slide() and velocity but we can change this if performance becomes a problem

@export var health: int = 10
@export var damage: int = 10
@export var speed: float = 100.0

func _ready():
	# Add to "enemies" group for targeting
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	# Default movement logic (can be overridden)
	move_enemy(delta)

func move_enemy(delta: float) -> void:
	# Example: Move right (override in child classes for custom behavior)
	velocity = Vector2(speed, 0)
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		die()

func die() -> void:
	queue_free()

func set_speed(new_speed: float) -> void:
	speed = new_speed
