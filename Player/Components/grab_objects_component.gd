extends Node

@export var camera: Camera3D
@export_group("Grab Settings")
@export var raycast: RayCast3D
@export var grab_force: float = 150.0
@export var max_rope_distance: float = 5.0
@export var scroll_step: float = 0.5
@export var min_grab_distance: float = 1.0

@export_group("Throw Settings")
@export var throw_speed: float = 10.0

@export_group("Visuals")
@export var grab_icon_texture: Texture2D
@export var icon_size: Vector2 = Vector2(0.2, 0.2)
@export var show_trajectory: bool = false

const GRAB_DAMPING: float = 10.0
const ANGULAR_LERP_RATE: float = 5.0
const DISTANCE_THRESHOLD: float = 0.1
const THROW_TORQUE_STRENGTH: float = 0.5

const THROW_NORMALIZER: float = 100

var grabbing_object: RigidBody3D = null
var grab_point_local: Vector3
var original_gravity_scale: float = 1.0
var original_angular_damp: float = 0.0
var original_linear_damp: float = 0.0

var grab_icon: Sprite3D
var trajectory_line: MeshInstance3D
var trajectory_material: StandardMaterial3D

var current_grab_distance: float = 2.0

var _target_position: Vector3
var _current_grab_point: Vector3

var _active_portal: Portal3D = null


func _ready() -> void:
	if grab_icon_texture:
		create_grab_icon()
	
	trajectory_line = MeshInstance3D.new()
	add_child(trajectory_line)
	
	trajectory_material = StandardMaterial3D.new()
	trajectory_material.albedo_color = Color(1, 0.5, 0, 0.8)
	trajectory_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	trajectory_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trajectory_material.no_depth_test = true


func create_grab_icon() -> void:
	grab_icon = Sprite3D.new()
	grab_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	grab_icon.no_depth_test = true
	grab_icon.scale = Vector3(icon_size.x, icon_size.y, 1.0)
	grab_icon.texture = grab_icon_texture
	grab_icon.visible = false
	grab_icon.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(grab_icon)


func _process(delta: float) -> void:
	if grabbing_object and not is_instance_valid(grabbing_object):
		release_grab()
		return
	
	if Input.is_action_just_pressed("fire") and not grabbing_object:
		try_grab()
	
	if Input.is_action_just_released("fire") and grabbing_object:
		release_grab()
	
	if grabbing_object:
		handle_scroll_input()
		update_grab(delta)
		update_grab_icon()
		draw_trajectory()
		
		if Input.is_action_just_released("throw"):
			throw_object()


func update_grab_icon() -> void:
	if not grab_icon: return
	
	grab_icon.visible = is_instance_valid(grabbing_object)
	if grab_icon.visible:
		grab_icon.global_position = grabbing_object.global_transform * grab_point_local

func handle_scroll_input() -> void:
	var scroll_up = Input.is_action_just_pressed("scroll_up")
	var scroll_down = Input.is_action_just_pressed("scroll_down")
	
	if scroll_up:
		current_grab_distance += scroll_step
	if scroll_down:
		current_grab_distance -= scroll_step
		
	current_grab_distance = clampf(current_grab_distance, min_grab_distance, max_rope_distance)


func try_grab() -> void:
	if not raycast: return
	
	raycast.force_raycast_update()
	
	var obj: RigidBody3D = null
	var grab_point_global: Vector3 = Vector3.ZERO
	var hit_portal: Portal3D = null
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		if collider.get_parent() is Portal3D or collider is Portal3D:
			var portal = collider.get_parent() as Portal3D
			var portal_result = portal.forward_raycast(raycast)
			print(portal)
			if portal_result and portal_result.collider is RigidBody3D:
				var portal_obj = portal_result.collider as RigidBody3D
				if portal_obj.is_in_group("grabbable"):
					obj = portal_obj
					grab_point_global = portal_result.position
					hit_portal = portal 
		else:
			obj = raycast.get_collider() as RigidBody3D
			grab_point_global = raycast.get_collision_point()
	
	if obj and obj.is_in_group("grabbable"):
		grabbing_object = obj
		_active_portal = hit_portal
		
		original_gravity_scale = obj.gravity_scale
		original_angular_damp = obj.angular_damp
		original_linear_damp = obj.linear_damp
		
		obj.linear_damp = GRAB_DAMPING
		obj.angular_damp = GRAB_DAMPING
		
		grab_point_local = obj.global_transform.affine_inverse() * grab_point_global
		
		if _active_portal:
			var cam_pos_in_exit: Vector3 = _active_portal.to_exit_transform(raycast.global_transform).origin
			current_grab_distance = cam_pos_in_exit.distance_to(grab_point_global)
		else:
			current_grab_distance = raycast.global_position.distance_to(grab_point_global)
			
		current_grab_distance = clampf(current_grab_distance, min_grab_distance, max_rope_distance)
		
		if grab_icon:
			grab_icon.visible = true
			grab_icon.global_position = grab_point_global


func release_grab() -> void:
	if is_instance_valid(grabbing_object):
		grabbing_object.gravity_scale = original_gravity_scale
		grabbing_object.linear_damp = original_linear_damp
		grabbing_object.angular_damp = original_angular_damp
	
	grabbing_object = null
	_active_portal = null
	
	if grab_icon:
		grab_icon.visible = false
		
	trajectory_line.mesh = null


func update_grab(delta: float) -> void:
	if not grabbing_object or not raycast: return
	
	var target_position: Vector3
	if _active_portal:
		var exit_ray_origin: Vector3 = _active_portal.to_exit_transform(raycast.global_transform).origin
		var exit_ray_dir: Vector3 = _active_portal.to_exit_direction(-raycast.global_basis.z)
		target_position = exit_ray_origin + (exit_ray_dir * current_grab_distance)
	else:
		target_position = raycast.global_position + (-raycast.global_basis.z * current_grab_distance)
	
	var current_grab_point = grabbing_object.global_transform * grab_point_local
	var direction = target_position - current_grab_point
	var distance = direction.length()
	
	if not _active_portal and distance > max_rope_distance + 0.5: 
		release_grab()
		return
	
	if distance > DISTANCE_THRESHOLD:
		var force = direction.normalized() * grab_force * (distance / current_grab_distance)
		
		var force_position = current_grab_point - grabbing_object.global_position
		
		grabbing_object.apply_force(force, force_position)
		grabbing_object.angular_velocity = lerp(grabbing_object.angular_velocity, Vector3.ZERO, ANGULAR_LERP_RATE * delta)
		
		_target_position = target_position
		_current_grab_point = current_grab_point


func throw_object() -> void:
	if not grabbing_object or not raycast: 
		release_grab()
		return
	
	if not camera:
		release_grab()
		return
	
	var throw_direction: Vector3
	if _active_portal:
		throw_direction = _active_portal.to_exit_direction(-camera.global_transform.basis.z.normalized())
	else:
		throw_direction = -camera.global_transform.basis.z.normalized()
	
	grabbing_object.gravity_scale = original_gravity_scale
	
	grabbing_object.apply_central_force(throw_direction * throw_speed * THROW_NORMALIZER / grabbing_object.mass)
	
	var random_torque = Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
	
	grabbing_object.apply_torque_impulse(random_torque * THROW_TORQUE_STRENGTH)
	release_grab()


func draw_trajectory() -> void:
	if not show_trajectory or not is_instance_valid(grabbing_object): 
		trajectory_line.mesh = null
		return
	
	var vertices := PackedVector3Array()
	vertices.push_back(_current_grab_point)
	vertices.push_back(_target_position)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh.surface_set_material(0, trajectory_material)
	
	trajectory_line.mesh = mesh
