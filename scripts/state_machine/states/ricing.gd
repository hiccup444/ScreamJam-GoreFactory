extends EnemyState

@warning_ignore("unused_parameter")
func enter(previous_state_path: String, data := {}) -> void:
	enemy.animation_player.play("Anim-Monster-Run")
	enemy.cur_speed = enemy.RUN_SPEED * 2
	enemy.animation_player.speed_scale = enemy.cur_speed / enemy.WALK_SPEED

func physics_update(_delta: float) -> void:
	if enemy.nav_agent.is_target_reached() and not idling:
		idling = true
		enemy.animation_player.speed_scale = 1
		enemy.animation_player.play("Anim-Monster-RiceLureStart")
		await enemy.animation_player.animation_finished
		enemy.animation_player.play("Anim-Monster-RiceLureLoop")
		await get_tree().create_timer(10).timeout
		idling = false
		finished.emit(WANDERING)
