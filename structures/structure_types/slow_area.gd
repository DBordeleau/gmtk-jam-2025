class_name SlowArea
extends Structure

@export var slow_range: float = 200.0

@onready var range_area: Area2D = $RangeArea
@onready var range_collider: CollisionShape2D = $RangeArea/RangeCollider

var slowed_enemies: Array = []


func _init():
	tooltip_desc = "A synthetic mini blackhole that greatly slows down everything around it. Halves the speed of all enemies within " + str(slow_range) + " range. Does not orbit the home planet."
	super._init()


# sets the collider size to match the range and connects the area2D signals
func _ready():
	if range_collider and range_collider.shape is CircleShape2D:
		range_collider.shape.radius = slow_range
	range_area.body_entered.connect(_on_body_entered)
	range_area.body_exited.connect(_on_body_exited)


# draws a bluish area to indicate the slow area
func _draw():
	draw_circle(Vector2.ZERO, slow_range, Color(0, 0.5, 1, 0.3))


# slows by half when enemies enter
func _on_body_entered(body):
	if body.is_in_group("enemies") and body not in slowed_enemies:
			slowed_enemies.append(body)
	if body.has_method("set_slow_multiplier"):
				body.set_slow_multiplier(0.5)  # Changed from set_speed to set_slow_multiplier




# returns speed to normal when enemies exit
func _on_body_exited(body):
	if body.is_in_group("enemies") and body in slowed_enemies:
		slowed_enemies.erase(body)
		if body.has_method("set_slow_multiplier"):
			body.set_slow_multiplier(1.0)


func update(delta: float) -> void:
	queue_redraw()


func update_tooltip_desc():
	tooltip_desc = "A synthetic mini blackhole that greatly slows down everything around it. Halves the speed of all enemies within " + str(slow_range) + " range. Does not orbit the home planet."


func update_range_display():
	queue_redraw()  # This will trigger _draw() to redraw with new range
