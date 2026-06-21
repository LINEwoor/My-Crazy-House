extends Node
class_name PushController

@export var can_push: bool = true
@export var push_force: float = 12
@export var is_invert : bool = false
const PUSH_FORCE_MULTIPLIER : float = 1


func push(character: CharacterBody3D, velocity : float):
	if not can_push: 
		return
	
	if is_invert: velocity *= -1
	
	for i in character.get_slide_collision_count():
		var collision = character.get_slide_collision(i)
		var collider = collision.get_collider()
	
		if collider is RigidBody3D:
			var push_direction = -collision.get_normal()
			(collider as RigidBody3D).apply_central_force(push_direction * push_force * PUSH_FORCE_MULTIPLIER * velocity)
