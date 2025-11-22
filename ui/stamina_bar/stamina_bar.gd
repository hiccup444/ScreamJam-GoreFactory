extends ProgressBar

var player: Player
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	modulate.a = 0
	player = get_tree().get_first_node_in_group("Player")
	max_value = player.MAX_STAMINA
	value = max_value
	
	value_changed.connect(func(v: float):
		if v == 0:
			animation_player.play("flash")
		elif v == max_value:
			animation_player.play("RESET")
	)

func _physics_process(_delta: float) -> void:
	value = player.cur_stamina
	if player.state == "sprinting" and modulate.a == 0:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "modulate:a", 1, 1)
	elif player.state != "sprinting" and modulate.a == 1 and value == max_value:
		var tween = get_tree().create_tween()
		tween.tween_property(self, "modulate:a", 0, 3)
