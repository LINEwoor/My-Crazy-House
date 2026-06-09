extends Node
class_name InteractiveObject

@export var object_name : String
signal onInteractive

func Interactive(character : Node):
	onInteractive.emit()
