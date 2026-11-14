extends CanvasLayer

@onready var close_button: Button = $MainPanel/Close_button
@onready var exit_game_button: Button = $MainPanel/Exit_game_button
@onready var audio_button: Button = $MainPanel/VBoxContainer/Audio_button
@onready var video_button: Button = $MainPanel/VBoxContainer/Video_button
@onready var controlls_button: Button = $MainPanel/VBoxContainer/Controlls_button
@onready var main_panel: Panel = $MainPanel
@onready var audio_panel: Panel = $AudioPanel
@onready var video_panel: Panel = $VideoPanel
@onready var controlls_panel: Panel = $ControllsPanel

@onready var audio_back_button: Button = $AudioPanel/Close_button
@onready var video_back_button: Button = $VideoPanel/Close_button
@onready var controlls_back_button: Button = $ControllsPanel/Close_button

var is_open : bool = false
var current_menu : Panel

@export var choose_level_btn : Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	exit_game_button.button_up.connect(exit_game)
	close_button.button_up.connect(toggle_menu)
	audio_button.button_up.connect(open_settings.bind("Audio"))
	video_button.button_up.connect(open_settings.bind("Video"))
	controlls_button.button_up.connect(open_settings.bind("Controlls"))

	audio_back_button.button_up.connect(back_to_main_menu)
	video_back_button.button_up.connect(back_to_main_menu)
	controlls_back_button.button_up.connect(back_to_main_menu)

	choose_level_btn.pressed.connect(_on_choose_level_pressed)

	main_panel.hide()
	audio_panel.hide()
	video_panel.hide()
	controlls_panel.hide()
	current_menu = main_panel


func _on_choose_level_pressed():
	if is_open:
		toggle_menu()
	await get_tree().process_frame
	get_tree().change_scene_to_file.call_deferred("uid://wj7f4ydii545")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu_toggle"):
		if current_menu != main_panel:
			back_to_main_menu()
		else:
			toggle_menu()


func exit_game() -> void:
	get_tree().quit()


func open_settings(name : String) -> void:
	var new_panel: Panel

	match name:
		"Audio":
			new_panel = audio_panel
		"Video":
			new_panel = video_panel
		"Controlls":
			new_panel = controlls_panel
		_:
			return

	current_menu.hide()
	new_panel.show()
	current_menu = new_panel


func back_to_main_menu() -> void:
	current_menu.hide()
	main_panel.show()
	current_menu = main_panel


func toggle_menu() -> void:
	is_open = !is_open
	if is_open:
		main_panel.show()
		current_menu = main_panel
		G.push_context(G.InputContext.MENU)
	else:
		current_menu.hide()
		current_menu = main_panel
		G.pop_context()
