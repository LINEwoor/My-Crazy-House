extends InteractiveObject
class_name Sofa

@export var director : AnimationPlayer

func Interactive(character : Player):
	if character is Player:
		var player : Player = character
		G.push_context(G.InputContext.LOCKED)
		await player.find_child("BlackScreen").sleep()
		player.global_position = Vector3(4.345, 2 , -58.764)
		player.rotation_degrees = Vector3(0,90,0)
		player.find_child("Head").rotation_degrees = Vector3.ZERO
		await get_tree().create_timer(2).timeout
		player.find_child("BlackScreen").wake_up(0.1)
		director.play("wake_up")
		await get_tree().create_timer(6).timeout
		player.find_child("BlackScreen")._set_darkness(1)
		G.pop_context()

		player.find_child("BlackScreen").fade_from_black(2)
		
