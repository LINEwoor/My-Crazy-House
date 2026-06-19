extends Node

signal inventory_updated(slot_index : int)
signal slot_selected(slot_index : int)
signal item_equipped(item: Item)
signal item_dropped(item: Item, position: Vector3)

const MAX_SLOTS: int = 5
@export var slots : Array[Item] = []

var current_index : int = 0

func _ready() -> void:
	await Engine.get_main_loop().process_frame
	select_slot(current_index)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("drop_item"):
		drop_item(current_index)

func _enter_tree() -> void:
	slots.resize(MAX_SLOTS)

func add_item(item : Item) -> bool:
	for i in range(MAX_SLOTS):
		if slots[i] == null:
			slots[i] = item
			inventory_updated.emit(i)
			
			if i == current_index:
				item_equipped.emit(item)
			
			return true
		elif slots[i].get_script() == item.get_script() and item.is_stackable:
			if i == current_index:
				item_equipped.emit(item)
			return false
	return false

func remove_item(index : int) -> Item:
	var item = slots[index]
	slots[index] = null
	inventory_updated.emit(index)
	if index == current_index:
		item_equipped.emit(null)
	return item

func use_item(index : int, user : Node):
	var item = slots[index]
	if item:
		var success = item.Use(user)
		if success and item.is_consumable:
			remove_item(index)
			item_equipped.emit(null)


func select_slot(index: int):
	if index >= 0 and index < MAX_SLOTS:
		current_index = index
		slot_selected.emit(current_index)
		var item = slots[current_index]
		item_equipped.emit(item)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("scroll_down"):
		current_index = (current_index + 1) % MAX_SLOTS
		slot_selected.emit(current_index)
		var item = slots[current_index]
		item_equipped.emit(item)
	elif event.is_action_pressed("scroll_up"):
		current_index = (current_index - 1 + MAX_SLOTS) % MAX_SLOTS
		slot_selected.emit(current_index)
		var item = slots[current_index]
		item_equipped.emit(item)
	
	for i in range(MAX_SLOTS):
		if event.is_action_pressed("slot_" + str(i + 1)):
			if i == current_index:
				use_item(current_index, get_tree().get_first_node_in_group("Player"))
			else:
				select_slot(i)

func spawn_item(item : Item):
	var interactable = load(item.interactable_scene).instantiate()
	interactable.item = item
	get_tree().current_scene.add_child(interactable)
	item_dropped.emit(interactable)

func drop_item(index : int):
	if slots[index]:
		var dropped_item = slots[index]
		spawn_item(dropped_item)
		remove_item(index)
