extends RayCast3D
class_name InteractiveRay

var _current_highlighted : PickupObject = null

func _resolve_interactive() -> InteractiveObject:
	var n := get_collider() as Node
	while n:
		if n is InteractiveObject:
			return n
		n = n.get_parent()
	return null

func _physics_process(_delta : float) -> void:
	var target := _resolve_interactive()
	var highlightable := target as PickupObject

	if highlightable != _current_highlighted:
		if _current_highlighted and is_instance_valid(_current_highlighted):
			_current_highlighted.set_outlined(false)
		_current_highlighted = highlightable
		if _current_highlighted:
			_current_highlighted.set_outlined(true, G.player)
	elif _current_highlighted:
		_current_highlighted.refresh_outline(G.player)

func _unhandled_input(event : InputEvent) -> void:
	if not event.is_action_pressed("Interactive"):
		return
	if G.is_player_frozen():
		return

	var interactive_object := _resolve_interactive()
	if not interactive_object:
		return
	if not interactive_object.can_interactive(G.player):
		return
	interactive_object.Interactive(G.player)
	get_viewport().set_input_as_handled()
