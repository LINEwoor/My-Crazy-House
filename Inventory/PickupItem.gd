extends Node
class_name PickupObject

@export var item: Item
@export var is_once : bool = true


func pickup(body : Node):
	if Inventory.add_item(item):
		if is_once:
			owner.call_deferred("queue_free")
	
	
