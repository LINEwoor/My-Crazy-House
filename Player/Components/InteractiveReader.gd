extends Node

@export var interactive_label: Label
@export var interactive_ray: InteractiveRay

func _process(delta: float) -> void:
	if interactive_ray.is_colliding():
		var obj = interactive_ray.get_collider()
		if obj is InteractiveObject and (obj as InteractiveObject).object_name != "" and (obj as InteractiveObject).can_interactive(owner):
			interactive_label.visible = true
			var actionButton : String = InputMap.action_get_events("Interactive")[0].as_text()
			if actionButton.contains(" - Physical"):
				actionButton = actionButton.replace(" - Physical","")
				actionButton = "[" + actionButton + "]"
			interactive_label.text = (obj as InteractiveObject).object_name + "\n" + actionButton
		else:
			interactive_label.visible = false
	else:
		interactive_label.visible = false
		
