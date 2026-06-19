extends InteractiveObject
class_name PickupObject

@export var item: Item

func Interactive(character : Node):
	if Inventory.add_item(item):
		call_deferred("queue_free")
	
	
