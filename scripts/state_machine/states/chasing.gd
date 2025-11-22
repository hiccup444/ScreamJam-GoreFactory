extends EnemyState

const JUMPSCARE_STING = preload("uid://6txl05f1wcd5")

var vision_lost_time: float = 0.0
var has_vision: bool = true
const VISION_LOSS_DELAY: float = 5.0

@warning_ignore("unused_parameter")
func enter(previous_state_path: String, data := {}) -> void:
	enemy.animation_player.play("Anim-Monster-Run")
	enemy.animation_player.speed_scale = enemy.RUN_SPEED / enemy.WALK_SPEED
	
	AudioManager.play(AudioManager.current_music_player, AudioManager.CHASE_THEME_LOOPABLE)
	if previous_state_path != CHASING:
		AudioManager.play_audio(JUMPSCARE_STING)
		AudioManager.play_3d(enemy.noise_player, AudioManager.THERE_YOU_ARE_ROBOT_ZOMBIE)
	enemy.cur_speed = enemy.RUN_SPEED
	
	# Reset vision tracking
	vision_lost_time = 0.0
	has_vision = true

func physics_update(delta: float) -> void:
	if player.is_safe:
		finished.emit(SEARCHING)

	if enemy.is_omniscient:
		enemy.nav_agent.target_position = player.global_position
		vision_lost_time = 0.0
		has_vision = true
		return
	
	if enemy.can_see_player():
		# Player is visible - reset timer and continue chasing
		vision_lost_time = 0.0
		has_vision = true
		enemy.nav_agent.target_position = player.global_position
	else:
		# Player is not visible - start/continue timer
		if has_vision:
			# Just lost vision
			has_vision = false
		
		vision_lost_time += delta
		
		# After 3 seconds of no vision, go to searching state
		if vision_lost_time >= VISION_LOSS_DELAY:
			finished.emit(SEARCHING)

func exit() -> void:
	# Reset vision tracking when leaving state
	vision_lost_time = 0.0
	has_vision = true
	AudioManager.stop(AudioManager.current_music_player, 1)
