extends AudioStreamPlayer3D

@export_group("Streams")
@export var footstep_stream: AudioStream

@export_group("Randomization")
@export var pitch_min: float = 0.9
@export var pitch_max: float = 1.1
@export var volume_min_db: float = -4.0
@export var volume_max_db: float = 0.0

@export var bobbing: Bobbing_node


func _ready() -> void:
	if bobbing:
		bobbing.footstep.connect(_play_footstep)


func _play_footstep() -> void:
	if footstep_stream == null:
		return
	if playing:
		return
	stream = footstep_stream
	pitch_scale = randf_range(pitch_min, pitch_max)
	volume_db = randf_range(volume_min_db, volume_max_db)
	play()