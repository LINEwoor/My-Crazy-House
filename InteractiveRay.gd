extends RayCast3D
class_name InteractiveRay

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Interactive"):
		var object = get_collider()
		
		if object and object is InteractiveObject:
			var interactive_object : InteractiveObject = object
			interactive_object.Interactive(owner)
