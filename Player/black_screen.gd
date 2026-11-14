extends ColorRect

@onready var mat: ShaderMaterial = material

func _ready() -> void:
	mat.set_shader_parameter("darkness", 0.0)
	mat.set_shader_parameter("use_eyelids", false)
	mat.set_shader_parameter("eyelid_amount", 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func fade_to_black(duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_method(_set_darkness, mat.get_shader_parameter("darkness"), 1.0, duration)

func fade_from_black(duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_method(_set_darkness, mat.get_shader_parameter("darkness"), 0.0, duration)

func _set_darkness(v: float) -> void:
	mat.set_shader_parameter("darkness", v)


func _set_eyelid(v: float) -> void:
	mat.set_shader_parameter("eyelid_amount", v)

func close_eyes(duration: float = 1.5) -> void:
	mat.set_shader_parameter("use_eyelids", true)
	var tween := create_tween()
	tween.tween_method(_set_eyelid, mat.get_shader_parameter("eyelid_amount"), 1.0, duration)
	await tween.finished

func open_eyes(duration: float = 1.5) -> void:
	mat.set_shader_parameter("use_eyelids", true)
	var tween := create_tween()
	tween.tween_method(_set_eyelid, mat.get_shader_parameter("eyelid_amount"), 0.0, duration)
	await tween.finished
	mat.set_shader_parameter("use_eyelids", false)

func sleep(duration: float = 2.0) -> void:
	mat.set_shader_parameter("use_eyelids", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_eyelid, 0.0, 1.0, duration)
	tween.tween_method(_set_darkness, mat.get_shader_parameter("darkness"), 1.0, duration)
	await tween.finished
	mat.set_shader_parameter("use_eyelids", false)

func wake_up(duration: float = 2.0) -> void:
	mat.set_shader_parameter("use_eyelids", true)
	mat.set_shader_parameter("eyelid_amount", 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_method(_set_eyelid, 1.0, 0.0, duration)
	tween.tween_method(_set_darkness, mat.get_shader_parameter("darkness"), 0.0, duration)
	await tween.finished
	mat.set_shader_parameter("use_eyelids", false)