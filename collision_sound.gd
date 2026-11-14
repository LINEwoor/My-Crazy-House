extends Node

@export var impact_sound: AudioStream
@export var min_impact_velocity: float = 1.5
@export var volume_db: float = 0.0
@export var max_distance: float = 20.0

var sound_player: AudioStreamPlayer3D
var _last_play_time: float = 0.0
const COOLDOWN := 0.1

func _ready():
	var body := owner as RigidBody3D
	if body == null:
		return

	body.contact_monitor = true
	body.max_contacts_reported = 4

	sound_player = get_node_or_null("ImpactSound")
	if sound_player == null:
		sound_player = AudioStreamPlayer3D.new()
		sound_player.name = "ImpactSound"
		add_child(sound_player)

	sound_player.stream = impact_sound
	sound_player.volume_db = volume_db
	sound_player.max_distance = max_distance

	body.body_entered.connect(_on_body_entered)

func _on_body_entered(_body):
	var body := owner as RigidBody3D
	if body.linear_velocity.length() < min_impact_velocity:
		return

	var now = Time.get_ticks_msec() / 1000.0
	if now - _last_play_time < COOLDOWN:
		return
	_last_play_time = now

	if sound_player.stream != null:
		sound_player.global_position = body.global_position
		sound_player.play()