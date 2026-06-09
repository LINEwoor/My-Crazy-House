extends Node
class_name PushController

@export var can_push: bool = true
@export var push_force: float = 12

func _process(delta: float) -> void:
	push(owner)

func push(character: CharacterBody3D):
	if not can_push: 
		return
	
	for i in character.get_slide_collision_count():
		var collision = character.get_slide_collision(i)
		var collider = collision.get_collider()
	
		if collider is RigidBody3D:
			var push_direction = -collision.get_normal()
			(collider as RigidBody3D).apply_central_force(push_direction * push_force)
