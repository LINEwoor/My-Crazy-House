extends RigidBody3D
class_name Painting

@export var trigger_area: Area3D
@export var beam_meshes: Array[MeshInstance3D] = []
@export var dust_particles: Array[GPUParticles3D] = []
@export var fade_duration: float = 1.0

func _ready():
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_STATIC
	if trigger_area:
		trigger_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == self or body == get_parent():
		return
	if !(body is RigidBody3D or body is CharacterBody3D):
		return
	if freeze:
		unfreeze()

func unfreeze() -> void:
	freeze = false

	fade_out_beams()
	hide_particles()

func get_mesh_material(mesh_instance: MeshInstance3D) -> Material:
	var mat = mesh_instance.get_surface_override_material(0)
	if mat != null:
		return mat

	if mesh_instance.material_override != null:
		return mesh_instance.material_override

	if mesh_instance.mesh != null:
		mat = mesh_instance.mesh.surface_get_material(0)
		if mat != null:
			return mat

	return null

func fade_out_beams() -> void:
	for mesh_instance in beam_meshes:
		if not is_instance_valid(mesh_instance):
			continue

		var mat = get_mesh_material(mesh_instance)
		if not (mat is ShaderMaterial):
			continue

		var current = mat.get_shader_parameter("intensity")
		if current == null:
			current = 1.0

		var tween = create_tween()
		tween.tween_method(
				func(value): mat.set_shader_parameter("intensity", value),
				current,
				0.0,
				fade_duration
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func hide_particles() -> void:
	for particles in dust_particles:
		if not is_instance_valid(particles):
			continue
		particles.emitting = false
		particles.visible = false
