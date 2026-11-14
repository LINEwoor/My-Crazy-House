extends Node

signal transition_finished(target_camera: Camera3D)

var _is_transitioning: bool = false
var _transition_cam: Camera3D = null
var _current_tween: Tween = null


func switch_to(next_cam: Camera3D, duration: float = 1.0,
		trans_type: Tween.TransitionType = Tween.TRANS_CUBIC,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT) -> void:

	if next_cam == null:
		return

	var viewport := get_viewport()
	var active_cam := viewport.get_camera_3d()

	if not _is_transitioning and active_cam == next_cam:
		next_cam.make_current()
		return

	if not _is_transitioning:
		if active_cam == null:
			next_cam.make_current()
			return

		_transition_cam = Camera3D.new()
		_transition_cam.name = "__TransitionCamera"
		add_child(_transition_cam)

		_transition_cam.top_level = true
		_transition_cam.global_position = active_cam.global_position
		_transition_cam.global_rotation = active_cam.global_rotation
		_transition_cam.fov = active_cam.fov
		_transition_cam.near = active_cam.near
		_transition_cam.far = active_cam.far
		_transition_cam.projection = active_cam.projection
		_transition_cam.size = active_cam.size
		_transition_cam.cull_mask = active_cam.cull_mask
		_transition_cam.environment = active_cam.environment
		_transition_cam.attributes = active_cam.attributes

		_transition_cam.make_current()
		_is_transitioning = true

	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		_current_tween = null

	var cam := _transition_cam
	var tween := create_tween()
	_current_tween = tween
	tween.set_parallel(true)
	tween.set_trans(trans_type)
	tween.set_ease(ease_type)

	tween.tween_property(cam, "global_position", next_cam.global_position, duration)
	tween.tween_property(cam, "global_rotation", next_cam.global_rotation, duration)
	tween.tween_property(cam, "fov", next_cam.fov, duration)
	tween.tween_property(cam, "near", next_cam.near, duration)
	tween.tween_property(cam, "far", next_cam.far, duration)

	await tween.finished

	if _current_tween != tween or not _is_transitioning:
		return

	next_cam.make_current()
	_current_tween = null
	_is_transitioning = false

	if is_instance_valid(_transition_cam):
		_transition_cam.queue_free()
	_transition_cam = null

	transition_finished.emit(next_cam)


func _create_transition_camera(source: Camera3D) -> Camera3D:
	var cam := Camera3D.new()
	cam.name = "__TransitionCamera"
	cam.top_level = true

	cam.global_position = source.global_position
	cam.global_rotation = source.global_rotation
	cam.fov = source.fov
	cam.near = source.near
	cam.far = source.far
	cam.projection = source.projection
	cam.size = source.size
	cam.cull_mask = source.cull_mask
	cam.environment = source.environment
	cam.attributes = source.attributes

	return cam
