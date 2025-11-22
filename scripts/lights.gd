extends Node3D

var lights: Array[OmniLight3D]
var player: Player

func _ready() -> void:
	show()
	player = get_tree().get_first_node_in_group("Player")
	for i in get_children():
		if i is OmniLight3D:
			lights.append(i)

func _physics_process(_delta: float) -> void:
	for light in lights:
		light.visible = light.global_position.distance_to(player.global_position) < 10
