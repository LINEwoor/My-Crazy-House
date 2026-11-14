extends AudioStreamPlayer3D

enum Trigger { JUMP, LAND }

@export var trigger: Trigger = Trigger.JUMP
@export var audio_stream: AudioStream
@export var player: Player

@export_group("Randomization")
@export var pitch_min: float = 0.9
@export var pitch_max: float = 1.1
@export var volume_min_db: float = -4.0
@export var volume_max_db: float = 0.0

@export_group("Land")
@export var land_volume_scale: float = 1.0


func _ready() -> void:
	if player == null:
		return
	if trigger == Trigger.JUMP:
		player.jumped.connect(_play_jump)
	elif trigger == Trigger.LAND:
		player.landed.connect(_play_land)


func _play_jump() -> void:
	_play(0.0)


func _play_land(_air_time: float) -> void:
	_play(land_volume_scale)


func _play(extra_volume_db: float) -> void:
	if audio_stream == null:
		return
	stream = audio_stream
	pitch_scale = randf_range(pitch_min, pitch_max)
	volume_db = randf_range(volume_min_db, volume_max_db) + extra_volume_db
	play()