class_name GameUI
extends CanvasLayer

@onready var interaction_ray: RayCast3D = %InteractionRay
@onready var interaction_prompt: Control = $Control
@onready var interaction_prompt_cta: Label = %InteractionPromptCTA
@onready var subtitle_label: RichTextLabel = %SubtitleLabel
@onready var note: Note = %Note

var ui_hidden: bool = false

func _ready() -> void:
	interaction_prompt.visible = false
	subtitle_label.visible = false
	
	# Connect subtitle signals
	if subtitle_label:
		subtitle_label.auto_hide_complete.connect(_on_subtitle_auto_hide_complete)
		subtitle_label.typing_finished.connect(_on_subtitle_typing_finished)
	
	# Connect to audio manager signals
	if AudioManager:
		AudioManager.dialogue_started.connect(_on_dialogue_started)
		AudioManager.dialogue_finished.connect(_on_dialogue_finished)

func _input(event: InputEvent) -> void:
	# Toggle UI visibility with P key (only in editor)
	if OS.has_feature("editor"):
		if event is InputEventKey and event.pressed and event.keycode == KEY_P:
			ui_hidden = !ui_hidden
			visible = !ui_hidden

func _physics_process(_delta: float) -> void:
	if UI.pause_menu.visible:
		interaction_prompt.visible = false
		return
	
	var obj: Interactable = interaction_ray.get_collider()
	
	if not obj:
		interaction_prompt.visible = false
	elif not obj.interactable:
		interaction_prompt.visible = false
	elif obj and not interaction_prompt.visible:
		interaction_prompt.visible = true
		interaction_prompt_cta.text = obj.cta
	elif not obj and interaction_prompt.visible:
		interaction_prompt.visible = false

func show_subtitle(text: String) -> void:
	"""Display a subtitle with typing animation."""
	subtitle_label.visible = true
	subtitle_label.display_subtitle(text)

func show_subtitle_resource(subtitle_data: SubtitleData) -> void:
	"""Display a subtitle from a SubtitleData resource."""
	subtitle_label.visible = true
	subtitle_label.display_subtitle_resource(subtitle_data)

func hide_subtitle() -> void:
	"""Hide the subtitle panel."""
	subtitle_label.visible = false
	subtitle_label.clear_subtitle()

func _on_subtitle_auto_hide_complete() -> void:
	"""Called when subtitle should auto-hide."""
	hide_subtitle()

func _on_subtitle_typing_finished() -> void:
	"""Called when subtitle typing animation completes."""
	pass  # Can add visual feedback here if needed

func _on_dialogue_started(dialogue_data: DialogueData) -> void:
	"""Called when audio manager starts playing dialogue."""
	# Check if subtitles are enabled before showing
	if not SettingsMenu.are_subtitles_enabled():
		return
	
	if dialogue_data and dialogue_data.subtitle_data:
		show_subtitle_resource(dialogue_data.subtitle_data)

func _on_dialogue_finished() -> void:
	"""Called when audio manager finishes playing dialogue."""
	# Only hide if subtitle doesn't have force_interaction enabled
	# (force_interaction subtitles stay until player dismisses them)
	if subtitle_label.current_subtitle_data and not subtitle_label.current_subtitle_data.force_interaction:
		# Let auto_hide handle it if enabled, otherwise hide immediately
		if not subtitle_label.current_subtitle_data.auto_hide:
			hide_subtitle()
