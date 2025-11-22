class_name DialogueTrigger
extends Area3D

## Triggers dialogue when player enters the area for the first time

@export var dialogue_data: DialogueData
@export var trigger_once: bool = true
@export var auto_enable: bool = true

var has_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if not auto_enable:
		monitoring = false

func _on_body_entered(body: Node3D) -> void:
	# Check if it's the player
	if not body is Player:
		return
	
	# Check if already triggered
	if trigger_once and has_triggered:
		return
	
	# Check if dialogue data is valid
	if not dialogue_data or not dialogue_data.is_valid():
		push_error("DialogueTrigger: Invalid dialogue data on " + name)
		return
	
	# Play the dialogue
	AudioManager.play_dialogue_with_subtitle(dialogue_data)
	has_triggered = true
	
	# Optionally disable monitoring after trigger
	if trigger_once:
		set_deferred("monitoring", false)

func reset_trigger() -> void:
	"""Manually reset the trigger to allow it to fire again."""
	has_triggered = false
	if not monitoring:
		monitoring = true

func enable_trigger() -> void:
	"""Enable the trigger if it was disabled."""
	monitoring = true

func disable_trigger() -> void:
	"""Disable the trigger."""
	monitoring = false
