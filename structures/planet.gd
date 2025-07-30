class_name Planet
extends StaticBody2D

signal planet_destroyed

@export var max_health: int = 100
var health: int = max_health
@onready var healthbar: ProgressBar = $Healthbar

# positions planet at the center of the screen and initializes the healthbar
func _ready():
	var viewport = get_viewport()
	global_position = viewport.get_visible_rect().size / 2
	_update_healthbar()

func take_damage(amount: int) -> void:
	print("Planet received", amount, "damage. Health before:", health)
	health -= amount
	if health < 0:
		health = 0
	_update_healthbar()
	if health <= 0:
		emit_signal("planet_destroyed")
		queue_free()

func get_health_percent() -> float:
	return float(health) / float(max_health)

func _update_healthbar() -> void:
	healthbar.max_value = max_health
	healthbar.value = health
