extends Panel
class_name Slot_UI

@onready var panel: Panel = $Panel
@onready var texture_rect: TextureRect = $TextureRect
@onready var label_counter: Label = $Label

var default_color: Color = Color(0.184, 0.184, 0.184)
var selected_color: Color = Color(0.779, 0.552, 0.0)

func _ready() -> void:
	set_selected(false)

func set_selected(selected: bool):
	if selected:
		panel.modulate = selected_color
	else:
		panel.modulate = default_color
