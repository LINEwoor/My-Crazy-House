extends Area3D
class_name ShadowLock

@export var progress_speed : float = 0.25
@export_range(0.1, 20.0) var decay_speed_multiplier : float = 4.0

@export var model : Node3D
@export var particles : GPUParticles3D

@export_group("Shake")
@export var shake_amplitude : float = 0.05
@export var shake_frequency : float = 18.0
@export_range(0.1, 30.0) var shake_response : float = 6.0

var is_active : bool
var progress : float = 0.0
var is_finished : bool = false

var _lit_amount : float = 0.0
var _is_lit : bool = false

var _rest_position : Vector3
var _shake_time : float = 0.0

func _ready() -> void:
	_rest_position = position

func set_lit(lit: bool) -> void:
	if is_finished:
		return
	_is_lit = lit

func _process(delta: float) -> void:
	if is_finished:
		return

	var target_lit := 1.0 if _is_lit else 0.0
	var factor := 1.0 - exp(-shake_response * delta)
	_lit_amount = lerp(_lit_amount, target_lit, factor)

	if _is_lit:
		is_active = true
		progress = clamp(progress + progress_speed * delta, 0.0, 1.0)
	elif progress > 0.0:
		is_active = false
		progress = clamp(progress - progress_speed * decay_speed_multiplier * delta, 0.0, 1.0)
	else:
		is_active = false

	_update_shake(delta)

	if progress >= 1.0:
		finish()

func finish() -> void:
	if is_finished:
		return
	set_deferred("monitorable", false)
	$CollisionShape3D.set_deferred("disabled", true)
	is_finished = true
	is_active = false
	_is_lit = false
	_lit_amount = 0.0
	position = _rest_position
	_shake_time = 0.0

	model.hide()
	particles.emitting = true
	particles.restart()

func _update_shake(delta: float) -> void:
	if is_finished or progress >= 1.0:
		position = _rest_position
		_shake_time = 0.0
		return

	var amp := shake_amplitude * _lit_amount * progress
	if amp <= 0.0001:
		position = _rest_position
		_shake_time = 0.0
		return

	_shake_time += delta
	var t := _shake_time * shake_frequency * TAU

	var offset := Vector3(
			sin(t * 1.0),
			sin(t * 1.37 + 1.7),
			sin(t * 0.83 + 3.1)
	) * amp
	position = _rest_position + offset