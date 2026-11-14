extends CharacterBody3D
class_name Player

signal jumped
signal landed(air_time: float)

enum State {WALK, CROUCH}
var state: State = State.WALK

@export var hand: Node3D
@export var item_offset: Vector3 = Vector3(0, -0.2, -0.5)
@export var item_rotation: Vector3 = Vector3(0, 0, 0)
@onready var head: Node3D = $Head

@export_category("Speed settings")
@export var walk_speed: float = 3
@export var sprint_speed: float = 5
@export var crouch_speed: float = 1
@export var jump_height: float = 1.5
@export var air_control: float = 0.3
var current_speed: float = walk_speed

@export_category("Timing settings")
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.15
@export var crouch_buffer_time: float = 0.2
@export var stand_check_delay: float = 0.05
@export var min_air_time_for_land: float = 0.2

@export_category("References")
@export var inventory : Inventory
@export var animator: AnimationPlayer
@export var roof_rays: Array[RayCast3D] = []
@export var footstep_audio_source : AudioStreamPlayer3D
@onready var interactive_ray: InteractiveRay = $Head/Bobbong_pivot/Interactive_ray

@export_category("Components")
@export var push_component: PushController

@export_category("Meshes and collisions")
@onready var stand_mesh: MeshInstance3D = $Stand_MeshInstance3D
@onready var stand_collision: CollisionShape3D = $Stand_CollisionShape3D
@onready var crouch_mesh: MeshInstance3D = $Chrouch_MeshInstance3D
@onready var crouch_collision: CollisionShape3D = $Chrouch_CollisionShape3D

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var crouch_buffer_timer: float = 0.0
var _stand_check_timer: float = 0.0
var _is_crouch_anim_playing: bool = false
var _air_time: float = 0.0

var current_item_instance: Node3D = null


func _ready() -> void:
	G.player = self

	if animator:
		animator.animation_finished.connect(_on_anim_finished)

	current_speed = walk_speed
	stand_collision.disabled = false
	crouch_collision.disabled = true
	stand_mesh.visible = true
	crouch_mesh.visible = false
	state = State.WALK

	Inventory.item_equipped.connect(_on_item_equipped)
	Inventory.item_dropped.connect(drop_from_player)

	_on_item_equipped(Inventory.slots[Inventory.current_index])


func _physics_process(delta: float) -> void:
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if crouch_buffer_timer > 0:
		crouch_buffer_timer -= delta

	var was_on_floor = is_on_floor()

	handle_movement(delta)
	handle_gravity(delta)
	handle_sprint()

	handle_crouch_logic(delta)
	handle_jump_logic()

	var pre_collision_velocity = velocity.length()
	move_and_slide()

	var on_floor := is_on_floor()

	if was_on_floor and !on_floor:
		coyote_timer = coyote_time
	elif on_floor:
		coyote_timer = 0.0
	elif coyote_timer > 0:
		coyote_timer -= delta

	if !on_floor:
		_air_time += delta
	elif !was_on_floor and on_floor:
		if _air_time >= min_air_time_for_land:
			landed.emit(_air_time)
		_air_time = 0.0

	if crouch_buffer_timer > 0 and is_on_floor() and not was_on_floor:
		if state == State.WALK:
			_set_crouch()
		crouch_buffer_timer = 0.0

	if push_component:
		push_component.push(self, pre_collision_velocity)


func handle_movement(delta: float):
	if G.is_player_frozen():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var move_dir = Input.get_vector("left_move", "right_move", "forward_move", "back_move")
	var movement = Vector3(move_dir.x, 0, move_dir.y).rotated(Vector3.UP, rotation.y)

	if is_on_floor():
		velocity.x = movement.x * current_speed
		velocity.z = movement.z * current_speed
	else:
		var target_vel = movement * current_speed
		velocity.x = lerp(velocity.x, target_vel.x, air_control)
		velocity.z = lerp(velocity.z, target_vel.z, air_control)


func handle_gravity(delta: float):
	if !is_on_floor():
		velocity.y += (get_gravity().y * 1.5) * delta
	else:
		if velocity.y < 0:
			velocity.y = 0


func handle_sprint():
	if G.is_player_frozen():
		return
	if state == State.CROUCH:
		return
	current_speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed


func handle_jump_logic():
	if G.is_player_frozen():
		return
	if state == State.CROUCH:
		return

	var can_jump = is_on_floor() or coyote_timer > 0

	if Input.is_action_just_pressed("jump"):
		if can_jump:
			_perform_jump()
		else:
			jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0 and can_jump:
		_perform_jump()
		jump_buffer_timer = 0


func _perform_jump():
	velocity.y = sqrt(2.0 * abs(get_gravity().y * 1.5) * jump_height)
	coyote_timer = 0
	jump_buffer_timer = 0
	jumped.emit()


func handle_crouch_logic(delta: float):
	if G.is_player_frozen():
		return

	if Input.is_action_just_pressed("crouch"):
		if state == State.WALK and not _is_crouch_anim_playing:
			_set_crouch()
		else:
			crouch_buffer_timer = crouch_buffer_time

	if Input.is_action_just_released("crouch"):
		crouch_buffer_timer = 0.0

	if state == State.CROUCH and not _is_crouch_anim_playing:
		if not Input.is_action_pressed("crouch"):
			if _can_stand():
				_stand_check_timer += delta
				if _stand_check_timer >= stand_check_delay:
					_stand_check_timer = 0.0
					_set_walk()
			else:
				_stand_check_timer = 0.0


func _set_crouch():
	if state == State.CROUCH:
		return
	state = State.CROUCH
	current_speed = crouch_speed

	crouch_collision.disabled = false
	stand_collision.disabled = true
	crouch_mesh.visible = true
	stand_mesh.visible = false

	if animator and animator.has_animation("StandToCrouch"):
		_is_crouch_anim_playing = true
		animator.play("StandToCrouch")


func _set_walk():
	if state == State.WALK:
		return

	if not _can_stand():
		return

	state = State.WALK
	current_speed = walk_speed if not Input.is_action_pressed("sprint") else sprint_speed

	stand_mesh.visible = true
	crouch_mesh.visible = false

	if animator and animator.has_animation("CrouchToStand"):
		_is_crouch_anim_playing = true
		animator.play("CrouchToStand")
	else:
		stand_collision.disabled = false
		crouch_collision.disabled = true


func _on_anim_finished(anim_name: StringName):
	_is_crouch_anim_playing = false

	if anim_name == "CrouchToStand":
		if _can_stand():
			stand_collision.disabled = false
			crouch_collision.disabled = true
		else:
			_set_crouch()

	elif anim_name == "StandToCrouch":
		pass


func _can_stand() -> bool:
	if roof_rays.is_empty():
		return true

	for ray in roof_rays:
		if ray:
			ray.force_raycast_update()
			if ray.is_colliding():
				return false

	return true


func _on_item_equipped(item: Item):
	if current_item_instance:
		current_item_instance.queue_free()
		current_item_instance = null

	if item and item.item_mesh:
		if not hand:
			return
		current_item_instance = item.item_mesh.instantiate()
		hand.add_child(current_item_instance)
		hand.rotation_degrees = item.mesh_rotation
		hand.scale = item.mesh_scale


func _unhandled_input(event: InputEvent) -> void:
	if G.is_player_frozen():
		return

	if event.is_action_pressed("use_item"):
		Inventory.use_item(inventory.current_index, self)
	if event.is_action_pressed("drop_item"):
		Inventory.drop_item(inventory.current_index)


func drop_from_player(item : Node3D):
	var forward : Vector3 = -interactive_ray.global_transform.basis.z.normalized()

	var space_state = get_world_3d().direct_space_state
	var from = interactive_ray.global_position
	var to = interactive_ray.global_position + forward * 1
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	var offset_distance = get_item_offset(item)

	if !result:
		item.global_position = to
	else:
		var spawn_position = result.position + result.normal * offset_distance
		item.global_position = spawn_position


func get_item_offset(item: Node3D) -> float:
	for child in item.get_children():
		if child is MeshInstance3D:
			var aabb = child.get_aabb()
			if aabb.size.length() > 0:
				return aabb.size.length() / 2.0 + 0.1

	for child in item.get_children():
		if child is CollisionShape3D and child.shape:
			var shape = child.shape
			if shape is BoxShape3D:
				return shape.size.length() / 2.0 + 0.1
			elif shape is SphereShape3D:
				return shape.radius + 0.1
			elif shape is CapsuleShape3D:
				return shape.radius + 0.1
	return 0.3