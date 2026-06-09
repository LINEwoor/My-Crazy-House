extends CharacterBody3D

@export var walk_speed : float = 3
@export var sprint_speed : float = 5
@export var jump_force : float = 1.5
@onready var current_speed : float = walk_speed

@export_category("Push rigidbodies")
@export var push_component : PushController 

func _physics_process(delta: float) -> void:
	handleMovement(delta)
	handleGravity(delta)
	handleSprint()
	handleJump()
	
	move_and_slide()
	if push_component:
		push_component.push(self)


func handleMovement(delta : float):
	if !G.can_move: return
	
	var move_dir = Input.get_vector("left_move","right_move", "forward_move", "back_move")
	var movement = Vector3(move_dir.x, 0, move_dir.y)
	movement = movement.rotated(Vector3.UP, rotation.y)
	movement *= current_speed
	
	velocity.x = movement.x
	velocity.z = movement.z

func handleGravity(delta : float):
	if !is_on_floor():
		velocity.y += get_gravity().y * delta
	else:
		if velocity.y < 0:
			velocity.y = 0

func handleSprint():
	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = walk_speed

func handleJump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(2 * abs(get_gravity().y) * jump_force)
