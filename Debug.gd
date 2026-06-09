extends Node


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_F1):
		get_tree().quit()
	if Input.is_key_pressed(KEY_F2):
		get_tree().reload_current_scene()
