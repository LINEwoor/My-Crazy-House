extends Node3D

@export var trigger: TriggerZone
@export var anim : AnimationPlayer
@export var anim_name : String

func _ready() -> void:
	trigger.player_entered.connect(_on_trigger_enter)

func _on_trigger_enter() -> void:
	anim.play(anim_name)
