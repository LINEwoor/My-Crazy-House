@tool
extends Panel

@export var levelData : DebugLevelData:
	set(value):
		if levelData and levelData.changed.is_connected(init_level):
			levelData.changed.disconnect(init_level)
		levelData = value
		if levelData and not levelData.changed.is_connected(init_level):
			levelData.changed.connect(init_level)
		if is_node_ready():
			init_level()

@export var button : Button
@export var icon : TextureRect
@export var name_label : Label
@export var description_label : RichTextLabel

func _ready() -> void:
	init_level()
	if not Engine.is_editor_hint():
		button.pressed.connect(_on_pressed)

func init_level():
	if levelData == null:
		if icon: icon.texture = null
		if name_label: name_label.text = ""
		if description_label: description_label.text = ""
		return
	if icon:
		icon.texture = levelData.custom_icon
	if name_label:
		name_label.text = levelData.display_name
	if description_label:
		description_label.text = levelData.description

func _on_pressed():
	get_tree().change_scene_to_packed(levelData.level_scene)