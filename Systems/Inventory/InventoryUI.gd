extends Node

@export var slots_container : HBoxContainer
@export var slot_prefab : PackedScene

@export var fade_duration: float = 0.3
@export var display_duration: float = 3.0

@onready var select_sound: AudioStreamPlayer = $SelectSound
@onready var select_empty_sound: AudioStreamPlayer = $SelectEmptySound


@onready var item_name_label: Label = $ItemNameLabel
@onready var item_description_label: Label = $ItemDescriptionLabel

var slots: Array[Slot_UI] = []
var hide_timer: Timer
var show_tween: Tween
var hide_tween: Tween
var current_item: Item = null
var is_visible: bool = false

func _ready() -> void:
	hide_timer = Timer.new()
	hide_timer.wait_time = display_duration
	hide_timer.one_shot = true
	hide_timer.timeout.connect(_on_display_timeout)
	add_child(hide_timer)
	
	item_name_label.modulate.a = 0.0
	item_description_label.modulate.a = 0.0
	item_name_label.visible = false
	item_description_label.visible = false
	
	for i in slots_container.get_child_count():
		slots_container.get_child(i).queue_free()
	
	for i in Inventory.MAX_SLOTS:
		var slot = slot_prefab.instantiate()
		slots_container.add_child(slot)
		slots.append(slot)
	
	Inventory.inventory_updated.connect(_on_inventory_updated)
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
		var item = Inventory.slots[index]
		_show_item_info(item)
		
		if item:
			select_sound.play()
		else:
			select_empty_sound.play()

func _on_inventory_updated(slot_index: int):
	update_slot(slot_index)
	if slot_index == Inventory.current_index:
		var item = Inventory.slots[slot_index]
		_show_item_info(item)

func _show_item_info(item: Item):
	if item:
		_stop_all_animations()
	hide_timer.stop()
	
	if item:
		current_item = item
		is_visible = true
		
		item_name_label.text = item.item_name
		item_description_label.text = item.description
		
		item_name_label.visible = true
		item_description_label.visible = true
		
		item_name_label.modulate.a = 0.0
		item_description_label.modulate.a = 0.0
		
		show_tween = create_tween()
		show_tween.set_parallel(true)
		show_tween.tween_property(item_name_label, "modulate:a", 1.0, fade_duration)
		show_tween.tween_property(item_description_label, "modulate:a", 1.0, fade_duration)
		show_tween.chain().tween_callback(_start_display_timer)
	else:
		_hide_item_info()

func _start_display_timer():
	if is_visible and current_item != null:
		hide_timer.start()

func _on_display_timeout():
	_hide_item_info()

func _hide_item_info():
	if not is_visible:
		return
	
	is_visible = false
	hide_timer.stop()
	
	if show_tween and show_tween.is_running():
		show_tween.stop()
	
	hide_tween = create_tween()
	hide_tween.set_parallel(true)
	hide_tween.tween_property(item_name_label, "modulate:a", 0.0, fade_duration)
	hide_tween.tween_property(item_description_label, "modulate:a", 0.0, fade_duration)
	hide_tween.chain().tween_callback(_on_hide_complete)

func _on_hide_complete():
	item_name_label.text = ""
	item_description_label.text = ""
	item_name_label.visible = false
	item_description_label.visible = false
	current_item = null

func _stop_all_animations():
	if show_tween and show_tween.is_running():
		show_tween.stop()
	
	if hide_tween and hide_tween.is_running():
		hide_tween.stop()
