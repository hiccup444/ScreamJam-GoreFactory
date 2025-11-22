extends StaticBody3D

var push_force = 0

var player: Player

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta):
	for i in player.get_slide_collision_count():
		var c = player.get_slide_collision(i)
		var collider := c.get_collider()
		if collider is StaticBody3D:
			collider.global_position += -c.get_normal() * _delta * 2
