extends CSGBox3D

@export var speed : float = 5


func _process(delta: float) -> void:
	global_position.z -= speed * delta