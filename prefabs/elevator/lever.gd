extends Interactable

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var elevator: Elevator = $".."
@onready var elevator_light: OmniLight3D = %Elevator_OmniLight3D

const LEVER_PULL = preload("uid://ordexqtsyiy1")

func interact() -> void:
	super.interact()
	if not interactable: return
	interactable = false
	
	# Mark that player entered elevator
	elevator.player_entered_elevator = true
	
	if animation_player:
		AudioManager.play_audio(LEVER_PULL)
		animation_player.play("pull_lever")
		await animation_player.animation_finished
		
		animation_player.play_backwards("open_gate")
		AudioManager.play_audio(AudioManager.ELEVATOR_DOOR_OPEN_CLOSE)
		await animation_player.animation_finished
		
		player.reparent(elevator.elevator_mesh)
		animation_player.play("move")
		AudioManager.play(AudioManager.ambience_player, AudioManager.ELEVATOR_LOOPABLE)
		
		# Wait a moment then start flickering
		await get_tree().create_timer(0.5).timeout
		await flicker_light(5)
		
		# Turn off light
		elevator_light.visible = false
		
		# Signal that we're loading with light off
		GameManager.elevator_light_off = true
		
		# Change scene immediately
		if elevator.next_level:
			GameManager.player_saved_elevator_pos = player.position
			GameManager.player_saved_head_rot = player.HEAD.rotation
			GameManager.player_saved_rot = player.rotation
			get_tree().change_scene_to_packed(elevator.next_level)

func flicker_light(count: int) -> void:
	for i in count:
		elevator_light.visible = false
		await get_tree().create_timer(0.05).timeout
		elevator_light.visible = true
		await get_tree().create_timer(0.1).timeout
