## Abstract structure class, don't instantiate this.
## Use AttackStructure, SlowStructure, etc.
class_name Structure
extends Node2D

@export var cost: int = 10
@export var speed: float = 1.0
var pos: Vector2 = Vector2.ZERO # pos because position is a default godot variable for Node2D
var is_orbital: bool = true # defines whether or not the structure can be placed outside of the loop path

@export var orbit_radius: float = 0.0
@export var orbit_idx: int = 0

# position will be determined by GameManager and set by the StructureManager
func _init():
	position = Vector2.ZERO

func update(delta: float) -> void:
	# override in subclasses (if necessary)
	pass
