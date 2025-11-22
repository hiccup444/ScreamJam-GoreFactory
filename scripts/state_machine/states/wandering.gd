extends EnemyState

@warning_ignore("unused_parameter")
func enter(previous_state_path: String, data := {}) -> void:
	if AudioManager.current_music_player.playing:
		AudioManager.stop(AudioManager.current_music_player, 2)
	enemy.animation_player.play("Anim-Monster-Walk")
	enemy.cur_speed = enemy.WALK_SPEED
	enemy.go_to_random_destination()

func physics_update(_delta: float) -> void:
	if enemy.velocity.length() < 0.5:
		enemy.animation_player.play("Anim-Monster-Idle")
		enemy.animation_player.speed_scale = 1
	else:
		enemy.animation_player.play("Anim-Monster-Walk")
		enemy.animation_player.speed_scale = enemy.cur_speed
	
	if enemy.can_see_player() and not player.is_safe:
		finished.emit(CHASING)
	elif player.talisman_active and not player.is_safe:
		if enemy.nav_agent.distance_to_target() > 25:
			enemy.cur_speed = 10
			
		enemy.nav_agent.target_position = player.global_position
	elif enemy.nav_agent.is_target_reached() and enemy.wandering_nav_points and not idling:
		print("Reached destination without seeing player. Wandering.")
		idling = true
		enemy.animation_player.speed_scale = 1
		enemy.animation_player.play("Anim-Monster-Idle")
		await get_tree().create_timer(3).timeout
		if not enemy.can_see_player():
			if enemy.global_position.distance_to(player.global_position) > 30 and not player.is_safe:
				enemy.go_to_dest_closest_to_player()
			else:
				enemy.go_to_random_destination()
		idling = false
