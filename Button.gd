extends InteractiveObject
class_name InteractiveButton

@export var objects : Array[InteractiveObject]

func Interactive(character):
	onInteractive.emit()
	
	for object in objects:
		object.Interactive(self)
