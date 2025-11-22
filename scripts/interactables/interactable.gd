class_name Interactable
extends Node3D

@export var interactable: bool = true
@export var cta: String = ""

var player: Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _input(event: InputEvent) -> void:
	if not interactable: return
	var obj: Interactable = player.get_looked_at_interactable()
	if not obj: return
	if event.is_action_pressed("interact") and self == obj:
		obj.interact()

func interact() -> void:
	player.animation_tree.active = false
	player.animation_player.play("Anim-Player-Interact")
	await player.animation_player.animation_finished
	player.animation_tree.active = true
	print("Interacting with: " + name)
