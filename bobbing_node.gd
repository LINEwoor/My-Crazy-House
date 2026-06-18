extends Node
class_name Bobbing_node

@export var freq : float = 5
@export var amp : float = 0.05
@export var freq_run : float = 10
@export var amp_run : float = 0.1
@export var rotation_amp : float = 0.5
@export var rotation_amp_run : float = 1.0
@onready var smooth_bob : int = 20
var time : float
@export var player : Player


@export var bobbing_pivot : Node3D

func _process(delta: float) -> void:
	if player.velocity.length() > 0 and player.is_on_floor():
		time += delta
		var bob_offset = Vector3.ZERO
		var rot_offset = Vector3.ZERO
		
		if player.current_speed == player.walk_speed:
			bob_offset.y = sin(freq * time * 1.5 + 1.0) * amp
			rot_offset.x = sin(freq * time * 1.2 + 0.5) * deg_to_rad(rotation_amp)
			rot_offset.y = -sin(freq/2 * time * 1.2 + 0.5) * deg_to_rad(rotation_amp/2)
			
		elif player.current_speed == player.sprint_speed:
			bob_offset.y = sin(freq_run * time * 1.5 + 1.0) * amp_run
			rot_offset.x = sin(freq_run * time * 1.2 + 0.5) * deg_to_rad(rotation_amp_run)
			rot_offset.y = -sin(freq_run/2 * time * 1.2 + 0.5) * deg_to_rad(rotation_amp_run/2)
		
		#bobbing_pivot.position = bobbing_pivot.position.lerp(bob_offset, delta * smooth_bob)
		bobbing_pivot.rotation = bobbing_pivot.rotation.lerp(rot_offset, delta * smooth_bob)
		
	else:
		#bobbing_pivot.position = bobbing_pivot.position.lerp(Vector3.ZERO, delta * 20)
		bobbing_pivot.rotation = bobbing_pivot.rotation.lerp(Vector3.ZERO, delta * 20)
		time = 0
