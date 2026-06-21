extends InteractiveObject
class_name InteractiveButton

@export var objects : Array[InteractiveObject]

func Interactive(character):
	if objects.size() == 0: return
	onInteractive.emit()
	 
	for object in objects:
		if object is InteractiveObject:
			object.Interactive(self)
