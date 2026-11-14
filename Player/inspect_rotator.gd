extends MeshInstance3D
class_name InspectRotator

@export var rotation_speed: float = 0.01
@export_range(0.0, 1.0, 0.01) var inertia: float = 0.85
@export var reset_button: MouseButton = MOUSE_BUTTON_MIDDLE
@export var camera : Camera3D

var _is_dragging: bool = false
var _angular_velocity: Vector2 = Vector2.ZERO
var _initial_rotation: Quaternion

func _ready() -> void:
	_initial_rotation = quaternion

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_is_dragging = event.pressed
		if event.button_index == reset_button and event.pressed:
			reset_rotation()

	if event is InputEventMouseMotion and _is_dragging:
		var delta_rot = event.relative * rotation_speed
		_angular_velocity = delta_rot
		_apply_rotation(delta_rot)

func _process(delta: float) -> void:
	if not _is_dragging and _angular_velocity.length() > 0.0001:
		_apply_rotation(_angular_velocity)
		_angular_velocity *= inertia
	else:
		_angular_velocity = Vector2.ZERO

func _apply_rotation(rot_delta: Vector2) -> void:
	var cam_right := camera.global_transform.basis.x
	var cam_up := camera.global_transform.basis.y

	rotate(cam_up, rot_delta.x)
	rotate(cam_right, rot_delta.y)

func reset_rotation() -> void:
	_angular_velocity = Vector2.ZERO
	quaternion = _initial_rotation