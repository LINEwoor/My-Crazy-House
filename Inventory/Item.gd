extends Resource
class_name Item

@export var item_name : String = "Item"
@export var description : String = "It`s item"
@export var icon : Texture2D = preload("uid://c3iefeucxf12a")
@export var item_mesh : PackedScene
@export_file var interactable_scene : String
@export var is_consumable : bool
@export var is_stackable: bool = false
@export var max_stack: int = 3

var current_stack: int

func Use(user: Node) -> bool:
	print("Used: ", item_name)
	return true
