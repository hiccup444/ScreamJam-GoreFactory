extends EnemyState

@warning_ignore("unused_parameter")
func enter(previous_state_path: String, data := {}) -> void:
	enemy.animation_player.play("Anim-Monster-Idle")
	enemy.animation_player.speed_scale = 1
	await get_tree().create_timer(randf_range(0, 5)).timeout
	if player.is_safe:
		finished.emit(WANDERING)
	elif not enemy.can_see_player() and not enemy.state_machine.state.name == DYING:
		finished.emit(WANDERING)

func physics_update(_delta: float) -> void:
	if enemy.can_see_player() and not player.is_safe:
		finished.emit(CHASING)
