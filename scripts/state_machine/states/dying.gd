extends EnemyState

@warning_ignore("unused_parameter")
func enter(previous_state_path: String, data := {}) -> void:
	enemy.animation_player.play("Anim-Monster-Shredded")
	enemy.animation_player.speed_scale = 1
