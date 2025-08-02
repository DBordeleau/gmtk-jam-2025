class_name AttackStructure
extends Structure

@export var attack_range: float = 120.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0
@export var cooldown_timer: float = 0.0
@export var orbit_angle: float = 0.0
@export var health: float = 10.0

@onready var range_collider: CollisionShape2D = $Range/RangeCollider

@export var death_particles: PackedScene

# Shield variables
var shield_visual: Node2D = null
var is_shielded: bool = false


func _ready():
	queue_redraw()
	if range_collider:
		range_collider.shape.radius = attack_range


func _process(delta):
	queue_redraw()


#draw_arc(Vector2.ZERO, attack_range, 0, TAU, 64, Color(1, 0, 0, 0.5), 2.0)

func take_damage(amount: float) -> void:
	# Check if this is an orbital structure and if shield is active
	if is_orbital and is_shielded:
		print("Damage blocked by shield!")
		return
		
	health -= amount
	print("New health: " + str(health))
	if health <= 0:
		var particle: Node = death_particles.instantiate()
		particle.position = global_position
		particle.rotation = global_rotation
		particle.emitting = true
		get_tree().current_scene.add_child(particle)
		if owner and owner.has_method("remove_structure"):
			owner.remove_structure(self)


func activate_shield():
	if not is_orbital:
		return
		
	is_shielded = true
	_create_shield_visual()


func deactivate_shield():
	if not is_orbital:
		return
		
	is_shielded = false
	_remove_shield_visual()


func _create_shield_visual():
	if shield_visual:
		return  # Shield visual already exists
	
	# Create a blue circle around the structure
	shield_visual = Node2D.new()
	shield_visual.name = "ShieldVisual"
	add_child(shield_visual)
	
	# Make sure it draws on top
	shield_visual.z_index = 10


func _remove_shield_visual():
	if shield_visual:
		shield_visual.queue_free()
		shield_visual = null


func _draw():
	# Draw attack range as a red circle
	draw_circle(Vector2.ZERO, attack_range, Color(1, 0, 0, 0.5))
	
	# Draw shield visual if active
	if is_shielded:
		var shield_radius = 30.0  # Small blue circle around the structure
		# Use engine ticks for smooth pulsing effect
		var pulse = sin(Time.get_ticks_msec() * 0.006) * 0.3 + 0.7
		var shield_color = Color(0.3, 0.7, 1.0, 0.6 * pulse)  # Blue with pulsing transparency
		draw_circle(Vector2.ZERO, shield_radius, shield_color)
		# Draw a slightly larger circle outline for better visibility
		draw_arc(Vector2.ZERO, shield_radius, 0, TAU, 32, Color(0.5, 0.8, 1.0, pulse), 3.0)


# Reduce CD every frame (not used rn)
func update(delta: float) -> void:
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		attack()
		cooldown_timer = attack_cooldown


# Doesn't do anything right now except collect enemies in range
func attack() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if position.distance_to(enemy.position) <= attack_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)


# Add this method to update the range indicator when attack_range changes
func update_range_display():
	if has_node("RangeIndicator"):
		var range_indicator             = $RangeIndicator
		var circle_shape: CircleShape2D = range_indicator.get_child(0).shape as CircleShape2D
		if circle_shape:
			circle_shape.radius = attack_range
	elif has_node("Range"):
		var range_area                  = $Range
		var circle_shape: CircleShape2D = range_area.get_child(0).shape as CircleShape2D
		if circle_shape:
			circle_shape.radius = attack_range
