extends InteractiveObject

@export var state_1_model : Node3D
@export var state_2_model : Node3D

func _ready() -> void:
	state_1_model.show()
	state_2_model.hide()

func Interactive(character : Player):
	get_tree().change_scene_to_file("uid://cdouv1x54k3o7")
