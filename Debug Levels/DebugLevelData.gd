@tool
extends Resource
class_name DebugLevelData

@export var level_scene : PackedScene
@export var custom_icon : Texture2D:
	set(value):
		custom_icon = value
		emit_changed()

@export var display_name : String:
	set(value):
		display_name = value
		emit_changed()

@export_multiline var description : String:
	set(value):
		description = value
		emit_changed()