## Controls behaviour of Asteroids.
extends Enemy
class_name Asteroid

@export var base_speed: float = 100.0

var spawn_position: Vector2
var total_distance: float = 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collider: CollisionShape2D = $CollisionShape2D

@export var target_position: Vector2 = Vector2.ZERO

var has_collided: bool = false # prevents double damage

@export var death_particles: PackedScene


# Set the target to the center of the screen
func _ready():
	var viewport: Viewport = get_viewport()
	target_position = viewport.get_visible_rect().size / 2
	spawn_position = global_position
	total_distance = spawn_position.distance_to(target_position)
	super._ready()


func _physics_process(delta: float) -> void:
	move_enemy(delta)
	_check_collisions()


func move_enemy(delta: float) -> void:
	var direction: Vector2       = (target_position - global_position).normalized()
	var distance_traveled: float = spawn_position.distance_to(global_position)
	var progress                 = clamp(distance_traveled / total_distance, 0.0, 1.0)

	var gravity_scale: float = 0.3 # 0.0 = no effect, 1.0 = strong effect
	var speed_bonus          = base_speed * gravity_scale * progress
	speed = (base_speed + speed_bonus) * slow_multiplier  # Apply slow multiplier here

	velocity = direction * speed
	move_and_slide()


# killed_by_player = false -- we dont want to award currency when asteroids die by colliding into the planet
func _check_collisions():
	if has_collided:
		return
	for i in range(get_slide_collision_count()):
		var collision: KinematicCollision2D = get_slide_collision(i)
		var collider: Object                = collision.get_collider()
		if collider and collider.has_method("take_damage"):
			print("Asteroid dealing", damage, "damage to", collider)
			collider.take_damage(damage)
			has_collided = true
			killed_by_player = false # Not killed by player!
			die()
			break


func die():
	# play particle fx
	var particle: Node = death_particles.instantiate()
	particle.position = global_position
	particle.rotation = global_rotation
	particle.emitting = true
	get_tree().current_scene.add_child(particle)
	death_sfx.play()
	super.die()
