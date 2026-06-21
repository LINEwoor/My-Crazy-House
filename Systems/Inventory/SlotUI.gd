extends Panel
class_name Slot_UI

@onready var panel: Panel = $Panel
@onready var texture_rect: TextureRect = $TextureRect
@onready var label_counter: Label = $Label

var default_color: Color = Color(0.184, 0.184, 0.184)
var selected_color: Color = Color(0.779, 0.552, 0.0)

var select_tween: Tween

func _ready() -> void:
	set_selected(false)

func set_selected(selected: bool) -> void:
	if select_tween and select_tween.is_running():
		select_tween.kill()
		
	select_tween = create_tween()
	select_tween.set_parallel(true)
	
	var target_color = selected_color if selected else default_color
	var target_scale = Vector2.ONE * 1.1 if selected else Vector2.ONE
	
	select_tween.tween_property(panel, "modulate", target_color, 0.15)
	
	select_tween.tween_method(
		func(new_scale: Vector2): set_offset_transform_scale(new_scale),
		get_offset_transform_scale(),
		target_scale,                  
		0.2                            
	).set_trans(Tween.TRANS_BACK)    
