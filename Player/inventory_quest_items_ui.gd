extends CanvasLayer
class_name InventoryQuestItemsUi

@export var prev_button : Button
@export var next_button : Button
@export var item_viewmodel : InspectRotator
@export var display_name_label : Label
@export var description_label : Label

var item_index : int = 0
var items : Array[Item] = []

var _spawned_instance : Node3D = null

func _ready() -> void:
	prev_button.pressed.connect(prev_item)
	next_button.pressed.connect(next_item)
	InventoryQuest.register_ui(self)

func _exit_tree() -> void:
	InventoryQuest.unregister_ui(self)
	_clear_spawned_instance()

func init(_items : Array[Item]) -> void:
	items.clear()
	if _items != null:
		items.assign(_items)
	item_index = 0
	open_by_index(item_index)

func open_by_index(index : int) -> void:
	if items.is_empty():
		prev_button.hide()
		next_button.hide()
		_clear_view()
		return

	item_index = clampi(index, 0, items.size() - 1)
	item_viewmodel.reset_rotation()

	prev_button.visible = item_index > 0
	next_button.visible = item_index < items.size() - 1

	var item : Item = items[item_index]
	if item == null:
		_clear_view()
		return

	display_name_label.text = item.item_name
	description_label.text = item.description
	item_viewmodel.scale = item.mesh_scale

	if item.inspector_scene != null:
		_set_view_scene(item.inspector_scene)
	elif item.item_mesh != null:
		_set_view_mesh(item.item_mesh)
	else:
		_clear_view()

func next_item() -> void:
	if item_index >= items.size() - 1:
		return
	open_by_index(item_index + 1)

func prev_item() -> void:
	if item_index <= 0:
		return
	open_by_index(item_index - 1)


func _set_view_mesh(mesh : Mesh) -> void:
	_clear_spawned_instance()
	item_viewmodel.mesh = mesh

func _set_view_scene(scene : PackedScene) -> void:
	_clear_spawned_instance()
	item_viewmodel.mesh = null

	var instance := scene.instantiate()
	if not (instance is Node3D):
		instance.queue_free()
		return

	_spawned_instance = instance
	item_viewmodel.add_child(instance)

	instance.position = items[item_index].mesh_position
	instance.rotation_degrees = items[item_index].mesh_rotation

func _clear_view() -> void:
	_clear_spawned_instance()
	item_viewmodel.mesh = null
	item_viewmodel.scale = Vector3.ONE
	display_name_label.text = ""
	description_label.text = ""

func _clear_spawned_instance() -> void:
	if is_instance_valid(_spawned_instance):
		_spawned_instance.queue_free()
	_spawned_instance = null
