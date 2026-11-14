extends Control

func _ready() -> void:
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_ESCAPE):
		await get_tree().process_frame
		get_tree().quit.call_deferred()
