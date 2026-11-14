extends Node

signal changed
signal opened
signal closed

var is_opened : bool = false
var items : Array[Item] = []

var _ui : InventoryQuestItemsUi = null


func register_ui(ui : InventoryQuestItemsUi) -> void:
	_ui = ui
	if _ui:
		_ui.hide()
		if is_opened:
			_ui.init(items)
			_ui.show()

func unregister_ui(ui : InventoryQuestItemsUi) -> void:
	if _ui == ui:
		_ui = null


func _unhandled_input(event : InputEvent) -> void:
	if not event.is_action_pressed("inventory_open"):
		return
	if is_opened:
		close()
		return
	if G.is_player_frozen():
		return
	open()

func open() -> void:
	if is_opened:
		return
	is_opened = true
	if _ui:
		_ui.init(items)
		_ui.show()
	G.push_context(G.InputContext.INVENTORY)
	opened.emit()

func close() -> void:
	if not is_opened:
		return
	is_opened = false
	if _ui:
		_ui.hide()
	G.pop_context()
	closed.emit()


func try_add_item(new_item : Item) -> bool:
	if new_item == null:
		return false

	if new_item.is_stackable:
		for existing in items:
			if existing != null \
					and existing.item_name == new_item.item_name \
					and existing.current_stack < existing.max_stack:
				existing.current_stack += 1
				_emit_changed()
				return true

	var copy : Item = new_item.duplicate()
	if copy.is_stackable:
		copy.current_stack = 1
	items.append(copy)
	_emit_changed()
	return true

func remove_item(target : Item, count : int = 1) -> bool:
	if target == null or count <= 0:
		return false
	var idx := items.find(target)
	if idx == -1:
		return false

	if target.is_stackable:
		target.current_stack -= count
		if target.current_stack <= 0:
			items.remove_at(idx)
	else:
		items.remove_at(idx)

	_emit_changed()
	return true

func count_item(item_id : StringName) -> int:
	var total : int = 0
	for it in items:
		if it == null or it.id != item_id:
			continue
		total += it.current_stack if it.is_stackable else 1
	return total

func has_item(item_id : StringName, count : int = 1) -> bool:
	if item_id.is_empty() or count <= 0:
		return false
	return count_item(item_id) >= count

func remove_by_item_id(item_id : StringName, count : int = 1) -> bool:
	if item_id.is_empty() or count <= 0:
		return false
	if count_item(item_id) < count:
		return false

	var remaining : int = count
	for i in range(items.size() - 1, -1, -1):
		var existing : Item = items[i]
		if existing == null or existing.id != item_id:
			continue
		if existing.is_stackable:
			var take : int = min(existing.current_stack, remaining)
			existing.current_stack -= take
			remaining -= take
			if existing.current_stack <= 0:
				items.remove_at(i)
		else:
			items.remove_at(i)
			remaining -= 1
		if remaining <= 0:
			break

	_emit_changed()
	return true

func find_item(item_id : StringName) -> Item:
	for it in items:
		if it != null and it.id == item_id:
			return it
	return null


func set_items(new_items : Array[Item]) -> void:
	items.clear()
	if new_items != null:
		items.assign(new_items)
	_emit_changed()


func _emit_changed() -> void:
	changed.emit()
	if is_opened and _ui:
		_ui.init(items)