extends Area3D

@export var player: AudioStreamPlayer3D
@export var stream: AudioStream

var has_played: bool = false

func _ready() -> void:
	body_entered.connect(trigger)

func trigger(_body: Node3D) -> void:
	if not stream or not player: return
	if has_played: return
	has_played = true
	AudioManager.play_3d(player, stream)
