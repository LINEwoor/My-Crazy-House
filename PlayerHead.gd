extends Node3D

@export var camera: Camera3D
@onready var player: CharacterBody3D = owner
@export var sensX : float = 0.001
@export var sensY : float = 0.001

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and G.can_head_rotate:
		player.rotate_y(-event.relative.x * sensX)
		rotate_x(-event.relative.y * sensY)
		
		rotation.x = clamp(rotation.x, 
			deg_to_rad(-85), 
			deg_to_rad(70))
