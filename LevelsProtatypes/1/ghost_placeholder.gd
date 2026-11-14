extends InteractiveObject
class_name GhostPlaceholder

signal installed

@export var needed_item_id : StringName = &''
@export var placeholder : Node3D
@export var model : Node3D
@export var audio_clip : AudioStream
@export var collectors : Array[Node3D]


func Interactive(character : Player):
	if not can_interactive(character):
		return
	super(character)
	install()

func install():
	if not (placeholder and model): return
	if not InventoryQuest.has_item(needed_item_id): return

	placeholder.hide()
	model.show()
	installed.emit()

	for collector in collectors:
		if collector and collector.has_method("_on_installed"):
			collector._on_installed(self)

	_play_sound_safe()
	InventoryQuest.remove_by_item_id(needed_item_id)

	queue_free()

func _play_sound_safe():
	if not audio_clip: return
	var parent := get_tree().current_scene
	if not parent: parent = get_tree().root
	if not parent: return

	var player := AudioStreamPlayer3D.new()
	player.stream = audio_clip
	player.bus = "SFX"
	player.finished.connect(player.queue_free)
	parent.add_child(player)
	player.global_position = model.global_position
	player.play()
