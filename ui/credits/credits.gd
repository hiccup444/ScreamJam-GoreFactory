extends Control

const MAIN_SCENE = preload("uid://dumalfa3kjsjn")

@onready var retry_button: Button = %RetryButton

func _ready() -> void:
	hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	retry_button.pressed.connect(on_retry_button_pressed)

func on_retry_button_pressed() -> void:
	hide()
	get_tree().change_scene_to_packed(MAIN_SCENE)
	UI.start_menu.show()
