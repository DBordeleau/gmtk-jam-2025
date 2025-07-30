class_name AttackStructure
extends Structure

@export var attack_range: float = 120.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0
@export var cooldown_timer: float = 0.0
@export var orbit_angle: float = 0.0
@export var health: float = 10.0

@onready var range_collider: CollisionShape2D = $Range/RangeCollider

func _ready():
	queue_redraw()
	if range_collider:
		range_collider.shape.radius = attack_range

func _process(delta):
	queue_redraw()

func _draw():
	# Draw attack range as a red circle
	draw_circle(Vector2.ZERO, attack_range, Color(1, 0, 0, 0.5))

func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0:
		if owner and owner.has_method("remove_structure"):
			owner.remove_structure(self)
		queue_free()
		
# Reduce CD every frame (not used rn)
func update(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		attack()
		cooldown_timer = attack_cooldown

# Doesn't do anything right now except collect enemies in range
func attack() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if position.distance_to(enemy.position) <= attack_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
