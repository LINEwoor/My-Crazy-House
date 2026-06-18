extends Node

@export var slots_container : HBoxContainer
@export var slot_prefab : PackedScene

var slots: Array[Slot_UI] = []

func _ready() -> void:
	for i in slots_container.get_child_count():
		slots_container.get_child(i).queue_free()
	
	for i in Inventory.MAX_SLOTS:
		var slot = slot_prefab.instantiate()
		slots_container.add_child(slot)
		slots.append(slot)
	
	Inventory.inventory_updated.connect(update_slot)
	Inventory.slot_selected.connect(_on_slot_selected)
	
	update_all_slots()


func update_slot(index : int):
	var item = Inventory.slots[index]
	var slot = slots[index]
	
	if item:
		slot.texture_rect.texture = item.icon
		slot.texture_rect.visible = true
	else:
		slot.texture_rect.visible = false
		

func update_all_slots():
	for i in range(Inventory.MAX_SLOTS):
		update_slot(i)
		
func _on_slot_selected(index: int):
	for slot in slots:
		slot.set_selected(false)
	
	if index < slots.size():
		slots[index].set_selected(true)
