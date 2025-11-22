extends Control

@onready var settings_scene = preload("res://ui/settings_menu/settings_menu.tscn")

@onready var return_button: Button = %ReturnButton
@onready var settings_button: Button = %SettingsButton
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton

func _ready():
	return_button.pressed.connect(_on_return_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	
	quit_button.visible = OS.get_name() != "Web"
	
	hide()

func _input(event):
	if event.is_action_pressed("pause") and GameManager.is_game_started:
		toggle_pause()

func toggle_pause():
	if UI.settings_menu.visible: return
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	visible = is_paused
	if is_paused: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_return_button_pressed():
	toggle_pause()

func _on_settings_button_pressed():
	UI.settings_menu.on_close = func():
		show()
		UI.settings_menu.hide()
	hide()
	UI.settings_menu.show()

func _on_restart_button_pressed():
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _on_quit_button_pressed():
	get_tree().paused = false
	get_tree().quit()
