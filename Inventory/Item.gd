extends Resource
class_name Item

@export var item_name : String = "Item"
@export var description : String = "It`s item"
@export var icon : Texture2D = preload("uid://c3iefeucxf12a")
@export var item_mesh : PackedScene
@export var interactable_scene : PackedScene
@export var is_stackable: bool = false
@export var max_stack: int = 3

var current_stack: int

func Use(user: Node) -> void:
	print("Used: ", item_name)
