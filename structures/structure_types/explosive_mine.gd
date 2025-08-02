class_name ExplosiveMine
extends Structure

@onready var range_collider: CollisionShape2D = $RangeArea/RangeCollider
@export var explosion_range: float = 180.0
@export var damage: int = 50
@onready var range_area: Area2D = $RangeArea
@export var explosion_particles: PackedScene
@onready var explode_sfx: AudioStreamPlayer = $ExplodeSFX
var health: int

func _init():
	cost = 10
	is_orbital = false
	health = 1 
	tooltip_name = "Explosive Mine"
	tooltip_desc = "A powerful explosive device that detonates when touched by an enemy. Deals " + str(damage) + " damage to ALL enemies within " + str(explosion_range) + " range. Single use."
	super._init()

func _ready():
	# Set up the explosion range (for damage detection)
	if range_collider and range_collider.shape is CircleShape2D:
		range_collider.shape.radius = explosion_range  # Keep this for damage area

func _draw():
	# Draw explosion range as orange circle (visual indicator only)
	draw_circle(Vector2.ZERO, explosion_range, Color(1, 0.5, 0, 0.3))
	# Draw a small center indicator
	draw_circle(Vector2.ZERO, 10, Color(1, 0, 0, 0.8))

func take_damage(amount: float) -> void:
	print("ExplosiveMine taking damage: ", amount)
	health -= amount
	if health <= 0:
		explode()

func explode():
	var camera = get_tree().get_root().get_node("GameManager/MainCamera") # so we can shake camera
	print("Mine exploding at position: ", global_position)
	
	# Get all enemies in explosion range
	var enemies_in_range = range_area.get_overlapping_bodies()
	print("Enemies in range: ", enemies_in_range.size())
	
	# Damage all enemies in range
	for enemy in enemies_in_range:
		if enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			print("Damaged enemy: ", enemy)
	
	# Spawn explosion particles if available
	if explosion_particles:
		var particles = explosion_particles.instantiate()
		particles.global_position = global_position
		particles.emitting = true
		get_tree().current_scene.add_child(particles)
	
		if explode_sfx:
			# Detach the audio player so it can finish playing
			explode_sfx.get_parent().remove_child(explode_sfx)
			get_tree().current_scene.add_child(explode_sfx)
			explode_sfx.play()
			# Optionally, queue_free the audio player after it finishes
			explode_sfx.finished.connect(func(): explode_sfx.queue_free())
	
	camera.shake(20.0, 0.5)
	
	# Remove from structure manager
	var structure_manager = get_tree().get_root().get_node("GameManager/StructureManager")
	if structure_manager:
		print("Removing mine from structure manager")
		structure_manager.structures.erase(self)
	
	print("Mine queued for deletion")
	queue_free()

func update(delta: float) -> void:
	queue_redraw()
	
func update_tooltip_desc():
	tooltip_desc = "A powerful explosive device that detonates when touched by an enemy. Deals " + str(damage) + " damage to ALL enemies within " + str(explosion_range) + " range. Single use."

func update_range_display():
	queue_redraw()  # This will trigger _draw() to redraw with new range
