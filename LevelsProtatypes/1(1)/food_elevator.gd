extends CSGBox3D
class_name FoodElevator

var is_up : bool = false
@export var animator : AnimationPlayer

func activate():
	if animator.is_playing():
		return
	if !is_up:
		animator.play("food_elevator")
	else:
		animator.play_backwards("food_elevator")
	
	is_up = !is_up
func _on_area_3d_player_entered() -> void:
	activate()
