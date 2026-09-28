extends CharacterBody3D
class_name Player

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
var current_speed: float

@export_category("Timing settings")
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.15
@export var crouch_buffer_time: float = 0.2
@export var stand_check_delay: float = 0.05

@export_category("References")
@export var inventory : Inventory
@export var animator: AnimationPlayer
@export var roof_checker: ShapeCast3D
@onready var interactive_ray: InteractiveRay = $Head/Bobbong_pivot/Interactive_ray

@export_category("Components")
@export var push_component: PushController

@export_category("Meshes and collisions")
@onready var stand_mesh: MeshInstance3D = $Stand_MeshInstance3D
@onready var stand_collision: CollisionShape3D = $Stand_CollisionShape3D
@onready var crouch_mesh: MeshInstance3D = $Chrouch_MeshInstance3D
@onready var crouch_collision: CollisionShape3D = $Chrouch_CollisionShape3D

var pending_crouch: bool = false
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var crouch_buffer_timer: float = 0.0
var current_item_instance: Node3D = null

var _transitioning: bool = false
var _stand_check_timer: float = 0.0


func _ready() -> void:
	if animator:
		animator.animation_finished.connect(_on_anim_finished)

	set_state(State.WALK)

	Inventory.item_equipped.connect(_on_item_equipped)
	Inventory.item_dropped.connect(drop_from_player)

	_on_item_equipped(Inventory.slots[Inventory.current_index])


func _physics_process(delta: float) -> void:
	update_buffers(delta)

	var was_on_floor = is_on_floor()

	handle_movement(delta)
	handle_gravity(delta)
	handle_sprint()
	handle_jump()
	handle_crouch()

	var pre_collision_velocity = velocity.length()
	move_and_slide()

	update_coyote_time(was_on_floor)

	handle_pending_crouch(was_on_floor)

	try_auto_stand(delta)

	if push_component:
		push_component.push(self, pre_collision_velocity)


func update_buffers(delta: float) -> void:
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
	if crouch_buffer_timer > 0:
		crouch_buffer_timer -= delta


func update_coyote_time(was_on_floor: bool):
	if was_on_floor and !is_on_floor():
		coyote_timer = coyote_time
	elif is_on_floor():
		coyote_timer = 0
	elif coyote_timer > 0:
		coyote_timer -= get_physics_process_delta_time()


func handle_movement(delta: float):
	if !G.can_move:
		return

	var move_dir = Input.get_vector(
			"left_move",
			"right_move",
			"forward_move",
			"back_move"
	)

	var movement = Vector3(move_dir.x, 0, move_dir.y)
	movement = movement.rotated(Vector3.UP, rotation.y)

	if is_on_floor():
		movement *= current_speed
		velocity.x = movement.x
		velocity.z = movement.z
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
	if state == State.CROUCH:
		return

	if Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
	else:
		current_speed = walk_speed


func handle_jump():
	var can_jump = is_on_floor() or coyote_timer > 0

	if Input.is_action_just_pressed("jump") and state != State.CROUCH:
		if can_jump:
			perform_jump()
		else:
			jump_buffer_timer = jump_buffer_time

	if jump_buffer_timer > 0 and (is_on_floor() or coyote_timer > 0) and state != State.CROUCH:
		perform_jump()
		jump_buffer_timer = 0


func perform_jump():
	velocity.y = sqrt(2.0 * abs(get_gravity().y * 1.5) * jump_height)
	coyote_timer = 0
	jump_buffer_timer = 0


func handle_crouch():
	if Input.is_action_just_pressed("crouch"):
		if is_on_floor() and state != State.CROUCH:
			set_state(State.CROUCH)
		elif !is_on_floor():
			pending_crouch = true
			crouch_buffer_timer = crouch_buffer_time

	if Input.is_action_just_released("crouch"):
		pending_crouch = false
		crouch_buffer_timer = 0


func handle_pending_crouch(was_on_floor: bool):
	var just_landed = is_on_floor() and not was_on_floor

	if pending_crouch and just_landed:
		if state != State.CROUCH:
			set_state(State.CROUCH)
		pending_crouch = false
		crouch_buffer_timer = 0
		return

	if crouch_buffer_timer > 0 and just_landed:
		if state != State.CROUCH:
			set_state(State.CROUCH)
		crouch_buffer_timer = 0
		pending_crouch = false
		return


func try_auto_stand(delta: float) -> void:
	if state != State.CROUCH or _transitioning:
		_stand_check_timer = 0.0
		return

	if Input.is_action_pressed("crouch"):
		_stand_check_timer = 0.0
		return

	if can_stand():
		_stand_check_timer += delta
		if _stand_check_timer >= stand_check_delay:
			_stand_check_timer = 0.0
			set_state(State.WALK)
	else:
		_stand_check_timer = 0.0


func can_stand() -> bool:
	if !roof_checker:
		return true

	roof_checker.force_shapecast_update()

	for i in roof_checker.get_collision_count():
		var collider = roof_checker.get_collider(i)
		# Игнорируем самого игрока и его потомков
		if collider == self:
			continue
		if collider is Node and is_ancestor_of(collider):
			continue
		return false

	return true


func set_state(new_state: State):
	if state == new_state or _transitioning:
		return

	var old_state = state
	state = new_state
	_transitioning = true
	_stand_check_timer = 0.0

	print("[Player] State changed: ", State.find_key(old_state), " -> ", State.find_key(new_state))

	match new_state:
		State.WALK:
			current_speed = walk_speed

			stand_collision.disabled = false
			crouch_collision.disabled = true

			if animator and old_state == State.CROUCH:
				animator.play("CrouchToStand")
			else:
				stand_mesh.visible = true
				crouch_mesh.visible = false
				_transitioning = false

		State.CROUCH:
			current_speed = crouch_speed

			stand_collision.disabled = true
			crouch_collision.disabled = false

			if animator and old_state == State.WALK:
				animator.play("StandToCrouch")
			else:
				stand_mesh.visible = false
				crouch_mesh.visible = true
				_transitioning = false


func _on_anim_finished(anim_name: StringName):
	match anim_name:
		"CrouchToStand":
			stand_mesh.visible = true
			crouch_mesh.visible = false
			_transitioning = false
		"StandToCrouch":
			stand_mesh.visible = false
			crouch_mesh.visible = true
			_transitioning = false


func _on_item_equipped(item: Item):
	if current_item_instance:
		current_item_instance.queue_free()
		current_item_instance = null

	if item and item.item_mesh:
		if not hand:
			return
		current_item_instance = item.item_mesh.instantiate()
		hand.add_child(current_item_instance)
		#hand.position = item.mesh_position
		hand.rotation_degrees = item.mesh_rotation
		hand.scale = item.mesh_scale
		#current_item_instance.position = item_offset
		#current_item_instance.rotation = item_rotation


func _unhandled_input(event: InputEvent) -> void:
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