extends Node
class_name InteractiveObject

@export var object_name : String
@export var oneshot : bool = false

var _was_interacted : bool = false

signal onInteractive

func _ready() -> void:
	_on_can_interactive_changed()

func Interactive(character : Player):
	if not can_interactive(character):
		return
	_was_interacted = true
	_on_can_interactive_changed()
	onInteractive.emit()

func can_interactive(_character : Player) -> bool:
	if oneshot and _was_interacted:
		return false
	if G.is_player_frozen(): return false
	return true

func _on_can_interactive_changed() -> void:
	pass