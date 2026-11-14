extends InteractiveObject
class_name PickupObject

@export var item : Item

var outline_available : ShaderMaterial = preload("uid://b5mpbi7m60pm4")
var outline_unavailable : ShaderMaterial = preload("uid://cfrlwyrgrntbk")

var _geometries : Array[GeometryInstance3D] = []
var _outlined : bool = false

func _ready() -> void:
	super._ready()
	if item != null:
		object_name = item.item_name
	_collect_geometries(self)

func _collect_geometries(node : Node) -> void:
	for child in node.get_children():
		if child is GeometryInstance3D and not (child is CSGCombiner3D):
			_geometries.append(child)
		_collect_geometries(child)

func Interactive(character : Player) -> void:
	if not can_interactive(character):
		return
	if item == null:
		return
	if not InventoryQuest.try_add_item(item):
		return
	set_outlined(false)
	super.Interactive(character)
	queue_free.call_deferred()


func set_outlined(enabled : bool, character : Player = null) -> void:
	if enabled:
		var ch := character if character else G.player
		var mat := outline_available if can_interactive(ch) else outline_unavailable
		for g in _geometries:
			if is_instance_valid(g):
				g.material_overlay = mat
		_outlined = true
	else:
		for g in _geometries:
			if is_instance_valid(g):
				g.material_overlay = null
		_outlined = false

func refresh_outline(character : Player = null) -> void:
	if _outlined:
		set_outlined(true, character)