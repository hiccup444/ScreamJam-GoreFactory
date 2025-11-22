extends Control

@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton

func _ready() -> void:
	play_button.pressed.connect(on_play_button_pressed)
	settings_button.pressed.connect(on_settings_button_pressed)
	credits_button.pressed.connect(on_credits_button_pressed)
	
	if GameManager.is_game_started:
		#if randf() < 0.5:
		AudioManager.play_dialogue_with_subtitle(AudioManager.HUH)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		hide()
	else:
		AudioManager.play(AudioManager.current_music_player, AudioManager.MENU_THEME)

func on_play_button_pressed() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0, 1)
	AudioManager.stop(AudioManager.current_music_player, 8)
	await tween.finished
	SignalBus.game_started.emit()
	hide()
	modulate.a = 1

func on_settings_button_pressed() -> void:
	UI.settings_menu.on_close = func():
		show()
		UI.settings_menu.hide()
	UI.settings_menu.show()
	hide()

func on_credits_button_pressed() -> void:
	var credits_scene = load("res://ui/credits_menu/credits_menu.tscn")
	var credits_menu = credits_scene.instantiate()
	credits_menu.on_close = func():
		show()
		credits_menu.queue_free()
	get_tree().root.add_child(credits_menu)
	hide()
