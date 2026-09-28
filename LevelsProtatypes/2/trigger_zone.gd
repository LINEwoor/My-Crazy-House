extends Area3D
class_name TriggerZone

signal player_entered
signal player_exited

@export var required_group: StringName = &"player"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(required_group):
		player_entered.emit()
		_activate(body)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(required_group):
		player_exited.emit()
		_deactivate(body)

func _activate(_body: Node3D) -> void:
	pass

func _deactivate(_body: Node3D) -> void:
	pass
