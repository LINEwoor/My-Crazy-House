extends Node3D
class_name Gears

@export var animator : AnimationPlayer
@export var audioSource : AudioStreamPlayer3D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _on_installed(_ghost: GhostPlaceholder):
	animator.play("gears")
	audioSource.play()
	
