extends InteractiveObject
class_name PickupObject

@export var item: Item

func _ready() -> void:
	if !item: return
	object_name = item.item_name

func Interactive(character : Node):
	Inventory.add_item( item)
	queue_free.call_deferred()
