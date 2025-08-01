class_name Planet
extends StaticBody2D

signal planet_destroyed
signal planet_damaged
@export var max_health: int = 100

var health: int             = max_health

@onready var healthbar: ProgressBar = $Healthbar


# positions planet at the center of the screen and initializes the healthbar
func _ready():
	var viewport: Viewport = get_viewport()
	global_position = viewport.get_visible_rect().size / 2
	_update_healthbar()


func take_damage(amount: int) -> void:
	print("Planet received", amount, "damage. Health before:", health)
	health -= amount
	if health < 0:
		health = 0
	_update_healthbar()

	# Emit planet_damaged signal when damage is taken
	emit_signal("planet_damaged")

	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(20.0, 1.0)

	if health <= 0:
		emit_signal("planet_destroyed")
		queue_free()


func get_health_percent() -> float:
	return float(health) / float(max_health)


func _update_healthbar() -> void:
	healthbar.max_value = max_health
	healthbar.value = health
