extends EnemyState

@warning_ignore("unused_parameter")
func enter(previous_state_path: String, data := {}) -> void:
	enemy.animation_player.play("Anim-Monster-Walk")
	enemy.animation_player.speed_scale = 1
	enemy.cur_speed = enemy.WALK_SPEED
	enemy.nav_agent.target_position = player.global_position

func physics_update(_delta: float) -> void:
	if enemy.can_see_player() and not player.is_safe:
		finished.emit(CHASING)
	elif (enemy.nav_agent.is_target_reached() or player.is_safe) and not idling:
		idling = true
		if enemy.nav_agent.is_target_reached():
			enemy.animation_player.play("Anim-Monster-Idle")
		await get_tree().create_timer(3).timeout
		idling = false
		if randf() < 0.35:
			AudioManager.play_dialogue_with_subtitle(AudioManager.FUCK_YOU)
		finished.emit(WANDERING)
