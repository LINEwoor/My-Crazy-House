extends InteractiveObject
class_name Valve

@export_group("State")
@export var is_available: bool = false
@export var placeholder: GhostPlaceholder
@export var area: Area3D
@export var camera: Camera3D

@export_group("Visual")
@export var visual: Node3D
@export var rotation_axis: Vector3 = Vector3.BACK
@export var label : Label3D

@export_group("Rotation")
@export var rotation_speed: float = 0.35
@export var progress: float = 0.0
@export var rotation_direction: int = 0

@export_group("Camera")
@export var camera_return_delay: float = 0.75
@export var camera_return_duration: float = 1.0

signal valve_complete
signal progress_changed(value: float)
signal valve_engaged
signal valve_disengaged

var _engaged: bool = false
var _is_finished: bool = false


func _ready() -> void:
	placeholder.installed.connect(on_valve_install)
	super()


func Interactive(character: Player) -> void:
	if not can_interactive(character):
		return
	super(character)
	_engage()


func _engage() -> void:
	if _engaged:
		return

	_engaged = true
	_is_finished = false

	camera.show()
	CameraSwitcher.switch_to(camera)
	G.push_context(G.InputContext.VALVE)

	valve_engaged.emit()
	progress_changed.emit(progress)


func _disengage() -> void:
	if not _engaged:
		return

	_engaged = false
	rotation_direction = 0

	valve_disengaged.emit()
	CameraSwitcher.switch_to(G.player_camera)

	await get_tree().create_timer(1.05).timeout

	if is_instance_valid(self):
		G.remove_context(G.InputContext.VALVE)

	_on_can_interactive_changed()


func _input(event: InputEvent) -> void:
	if not _engaged:
		return

	if event.is_action_pressed("ui_cancel"):
		_disengage()
		get_viewport().set_input_as_handled()
		return

	if _is_finished:
		return

	if event.is_action_pressed("valve_rotate_left"):
		rotation_direction = -1
	elif event.is_action_pressed("valve_rotate_right"):
		rotation_direction = 1
	elif event.is_action_released("valve_rotate_left") and rotation_direction == -1:
		rotation_direction = 0
	elif event.is_action_released("valve_rotate_right") and rotation_direction == 1:
		rotation_direction = 0


func _process(delta: float) -> void:
	if not _engaged or _is_finished:
		return
	if rotation_direction == 0:
		return

	var new_progress := clampf(
			progress + rotation_direction * rotation_speed * delta,
			0.0, 1.0
	)

	if is_equal_approx(new_progress, progress):
		rotation_direction = 0
		return

	var delta_progress := new_progress - progress
	progress = new_progress
	progress_changed.emit(progress)
	label.text = "%d/100" % [progress * 100]

	if visual:
		visual.rotate(rotation_axis, sign(delta_progress) * abs(delta_progress) / rotation_speed * TAU)

	if progress >= 1.0:
		_finish()


func _finish() -> void:
	if _is_finished:
		return
	_is_finished = true
	rotation_direction = 0

	valve_complete.emit()
	print("Valve Complete!")

	await get_tree().create_timer(camera_return_delay).timeout
	_disengage()


func on_valve_install() -> void:
	is_available = true
	_on_can_interactive_changed()


func can_interactive(character: Player) -> bool:
	if not is_available:
		return false
	if _is_finished:
		return false
	if _engaged:
		return false
	return super(character)


func _on_can_interactive_changed() -> void:
	if area:
		area.set_deferred("monitoring", can_interactive(null))