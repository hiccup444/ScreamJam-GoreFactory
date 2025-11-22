class_name Note
extends Control

@onready var text: Label = %Text
@onready var paper_texture_rect: TextureRect = %PaperTextureRect

func _ready() -> void:
	visible = false

func _input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("ui_back") or event.is_action_pressed("pause"):
		hide_note()

func show_note() -> void:
	visible = true
	get_tree().paused = true
	Player.is_reading = true

func hide_note() -> void:
	visible = false
	get_tree().paused = false
	Player.is_reading = false
