extends Item
class_name KeyItem

@export var key_id : int = -1


func Use(user: Node) -> bool:
	var player : Player = user
	var player_ray = player.interactive_ray
	if player_ray.is_colliding():
		var obj = player_ray.get_collider()
		if obj is Door:
			var door : Door = obj
			if door.isLocked and door.lock_id == key_id:
				door.unlock()
				if not door.isLocked:
					door.open_door()
					return true
				return false
			return false
		return false
		
	return false
