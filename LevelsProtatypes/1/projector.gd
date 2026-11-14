extends InteractiveObject
class_name Projector

@export var camera : Camera3D
@export var light : SpotLight3D
@export var raycast : RayCast3D
@export var yaw_pivot : Node3D
@export var pitch_pivot : Node3D

@export_group("Rotation")
@export var rotation_speed : float = 60.0
@export_range(0.1, 20.0) var acceleration : float = 8.0
@export_range(0.1, 20.0) var deceleration : float = 3.0

@export_group("Light Angle")
@export var spot_angle_locked : float = 1.0
@export var spot_angle_normal : float = 2.5
@export_range(0.1, 30.0) var spot_angle_smoothing : float = 6.0

@export_group("Camera Zoom")
@export var zoom_fov : float = 40.0
@export_range(0.1, 30.0) var zoom_smoothing : float = 6.0

@export_group("Limits (degrees, relative to initial)")
@export_range(-180.0, 180.0) var min_pitch_deg : float = -45.0
@export_range(-180.0, 180.0) var max_pitch_deg : float = 45.0
@export_range(-180.0, 180.0) var min_yaw_deg : float = -60.0
@export_range(-180.0, 180.0) var max_yaw_deg : float = 60.0

var is_available : bool
var is_active : bool

var current_pitch : float = 0.0
var current_yaw : float = 0.0

var base_pitch : float = 0.0
var base_yaw : float = 0.0

var _velocity_yaw : float = 0.0
var _velocity_pitch : float = 0.0

var _target_spot_angle : float = 0.0
var _current_spot_angle : float = 0.0

var _current_lit_target : ShadowLock = null

var _base_fov : float = 75.0
var _target_fov : float = 75.0

var _activated_frame : int = -1


func _ready() -> void:
	base_pitch = rad_to_deg(pitch_pivot.rotation.z)
	base_yaw   = rad_to_deg(yaw_pivot.rotation.y)
	_current_spot_angle = spot_angle_normal
	_target_spot_angle  = spot_angle_normal
	light.spot_angle = _current_spot_angle

	_base_fov   = camera.fov
	_target_fov = _base_fov


func Interactive(character : Player):
	if G.is_player_frozen():
		return
	if !is_available:
		return
	if !is_active:
		activate()


func can_interactive(_character : Player) -> bool:
	if is_active or !is_available:
		return false
	return true


func _process(delta: float) -> void:
	if !is_active:
		return

	var dir = Input.get_vector("left_move", "right_move", "back_move", "forward_move")

	var target_yaw_vel   : float = -dir.x * rotation_speed
	var target_pitch_vel : float = -dir.y * rotation_speed

	_velocity_yaw   = _smooth_velocity(_velocity_yaw,   target_yaw_vel,   delta)
	_velocity_pitch = _smooth_velocity(_velocity_pitch, target_pitch_vel, delta)

	if abs(_velocity_yaw)   < 0.01 and dir.x == 0.0: _velocity_yaw   = 0.0
	if abs(_velocity_pitch) < 0.01 and dir.y == 0.0: _velocity_pitch = 0.0

	current_yaw   = clamp(current_yaw   + _velocity_yaw   * delta, min_yaw_deg,   max_yaw_deg)
	current_pitch = clamp(current_pitch + _velocity_pitch * delta, min_pitch_deg, max_pitch_deg)

	if current_yaw   == min_yaw_deg   or current_yaw   == max_yaw_deg:
		_velocity_yaw = 0.0
	if current_pitch == min_pitch_deg or current_pitch == max_pitch_deg:
		_velocity_pitch = 0.0

	yaw_pivot.rotation.y   = deg_to_rad(base_yaw   + current_yaw)
	pitch_pivot.rotation.z = deg_to_rad(base_pitch + current_pitch)

	var lit_target : ShadowLock = null
	if raycast.is_colliding():
		var obj := raycast.get_collider()
		if obj is ShadowLock:
			lit_target = obj

	if _current_lit_target and _current_lit_target != lit_target:
		_current_lit_target.set_lit(false)
	if lit_target:
		lit_target.set_lit(true)
	_current_lit_target = lit_target

	var valid_target := lit_target != null and not lit_target.is_finished

	_target_spot_angle = spot_angle_locked if valid_target else spot_angle_normal

	var factor := 1.0 - exp(-spot_angle_smoothing * delta)
	_current_spot_angle = lerp(_current_spot_angle, _target_spot_angle, factor)
	if abs(_current_spot_angle - _target_spot_angle) < 0.001:
		_current_spot_angle = _target_spot_angle
	light.spot_angle = _current_spot_angle

	_target_fov = zoom_fov if valid_target else _base_fov

	var zoom_factor := 1.0 - exp(-zoom_smoothing * delta)
	camera.fov = lerp(camera.fov, _target_fov, zoom_factor)
	if abs(camera.fov - _target_fov) < 0.01:
		camera.fov = _target_fov


func _smooth_velocity(current: float, target: float, delta: float) -> float:
	var accelerating = abs(target) > abs(current) and sign(target) == sign(current)
	if sign(target) != sign(current) and target != 0.0:
		accelerating = true
	var rate := acceleration if accelerating else deceleration
	var factor := 1.0 - exp(-rate * delta)
	return lerp(current, target, factor)


func _unhandled_input(event: InputEvent) -> void:
	if !is_active:
		return
	if event.is_action_pressed("Interactive"):
		if Engine.get_process_frames() == _activated_frame:
			return
		deactivate()
		get_viewport().set_input_as_handled()


func activate():
	G.push_context(G.InputContext.LOCKED)
	CameraSwitcher.switch_to(camera, 0)
	is_active = true
	_activated_frame = Engine.get_process_frames()
	camera.fov = _base_fov
	_target_fov = _base_fov


func deactivate():
	if not is_active:
		return
	G.pop_context()
	CameraSwitcher.switch_to(G.player_camera, 0)
	is_active = false
	_velocity_yaw   = 0.0
	_velocity_pitch = 0.0
	if _current_lit_target:
		_current_lit_target.set_lit(false)
		_current_lit_target = null
	_target_spot_angle = spot_angle_normal
	camera.fov = _base_fov
	_target_fov = _base_fov


func _on_installed(_ghost: GhostPlaceholder):
	is_available = true
