extends HSlider

enum AudioBus {
	MASTER = 0,
	MUSIC = 1,
	SFX = 2,
	UI = 3
}

@export var audio_bus: AudioBus = AudioBus.MASTER
@export var test_audio : AudioStreamPlayer

var save_key: String = ""
var bus_index: int = -1
var bus_names: Dictionary = {
	AudioBus.MASTER: "Master",
	AudioBus.MUSIC: "Music",
	AudioBus.SFX: "SFX",
	AudioBus.UI: "UI",
}


func _ready() -> void:
	save_key = bus_names[audio_bus].to_lower() + "_volume"
	
	_update_bus_index()
	load_volume()
	
	value_changed.connect(_on_value_changed)
	drag_ended.connect(_on_drag_ended)


func _update_bus_index() -> void:
	var bus_name_string = bus_names[audio_bus]
	bus_index = AudioServer.get_bus_index(bus_name_string)
	
	if bus_index == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name_string)
		bus_index = AudioServer.get_bus_index(bus_name_string)


func _on_value_changed(value: float) -> void:
	var db_value = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db_value)
	save_volume()


func _on_drag_ended(value: float) -> void:
	if test_audio:
		if test_audio.playing:
			test_audio.stop()
		test_audio.bus = AudioServer.get_bus_name(bus_index)
		test_audio.play()


func load_volume() -> void:
	var config = ConfigFile.new()
	var path = "user://settings.cfg"
	
	if FileAccess.file_exists(path):
		var error = config.load(path)
		if error == OK:
			if config.has_section_key("audio", save_key):
				var saved_volume = config.get_value("audio", save_key)
				value = saved_volume
				var db_value = linear_to_db(value)
				AudioServer.set_bus_volume_db(bus_index, db_value)
				return
	
	if bus_index != -1:
		var current_db = AudioServer.get_bus_volume_db(bus_index)
		value = db_to_linear(current_db)


func save_volume() -> void:
	var config = ConfigFile.new()
	var path = "user://settings.cfg"
	
	if FileAccess.file_exists(path):
		config.load(path)
	
	config.set_value("audio", save_key, value)
	config.save(path)


func load_from_config_file() -> void:
	load_volume()


static func get_available_buses() -> Array:
	var buses = []
	for i in range(AudioServer.bus_count):
		buses.append(AudioServer.get_bus_name(i))
	return buses


func refresh_bus_list() -> void:
	_update_bus_index()
	if bus_index != -1:
		var current_db = AudioServer.get_bus_volume_db(bus_index)
		value = db_to_linear(current_db)
