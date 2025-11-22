extends Node

var is_game_started: bool = false
var has_looked_down: bool = false

var player: Player
var player_saved_elevator_pos: Vector3 = Vector3.ZERO
var player_saved_head_rot: Vector3 = Vector3.ZERO
var player_saved_rot: Vector3 = Vector3.ZERO
var env: WorldEnvironment
var elevator_light_off: bool = false

func _ready() -> void:
	SignalBus.game_started.connect(_on_game_started)
	SignalBus.player_killed.connect(_on_player_killed)
	SignalBus.game_won.connect(_on_game_won)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("primary_fire") \
	and is_game_started \
	and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE\
	and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func fade_vision(to: float, time: float = 3) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(env, "environment:tonemap_exposure", to, time)
	await tween.finished

func reset_game_state() -> void:
	"""Reset all game state to initial values"""
	# GameManager state
	is_game_started = false
	has_looked_down = false
	player = null
	player_saved_elevator_pos = Vector3.ZERO
	player_saved_head_rot = Vector3.ZERO
	player_saved_rot = Vector3.ZERO
	env = null
	elevator_light_off = false
	
	# AudioManager state
	AudioManager.stop_dialogue()
	AudioManager.current_dialogue_data = null
	AudioManager.dialogue_paused = false
	AudioManager.dialogue_pause_position = 0.0
	
	# Stop all AudioManager players
	#if AudioManager.current_music_player and AudioManager.current_music_player.playing:
		#AudioManager.current_music_player.stop()
	if AudioManager.breathing_player and AudioManager.breathing_player.playing:
		AudioManager.breathing_player.stop()
	# Don't stop ambience_player as it gets restarted in reset anyway
	
	# Player static variables
	Player.is_reading = false

func reset_visuals() -> void:
	# TODO: Redundant probably but idc
	env = get_tree().get_first_node_in_group("WorldEnvironment")
	env.environment.adjustment_contrast = 1
	player = get_tree().get_first_node_in_group("Player")
	if player.talisman_active:
		player.toggle_talisman()
	player.enemy.set_see_thru_walls(false)

func _on_game_started() -> void:
	if not is_game_started: is_game_started = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player = get_tree().get_first_node_in_group("Player")
	player.animation_tree.active = true
	reset_visuals()

func _on_player_killed() -> void:
	env = get_tree().get_first_node_in_group("WorldEnvironment")
	await fade_vision(0)
	env.environment.tonemap_exposure = 1
	reset_visuals()
	get_tree().reload_current_scene()

func _on_game_won() -> void:
	AudioManager.play(AudioManager.current_music_player, AudioManager._80S_POP_THEME)
	is_game_started = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	UI.game_over.show()
	UI.game_over.modulate.a = 0.0
	get_tree().create_tween().tween_property(UI.game_over, "modulate:a", 1.0, 3.0)
	var credits := preload("res://ui/credits_menu/credits_menu.tscn").instantiate()
	UI.game_over.add_child(credits)
	
	credits.on_close = func():
		# Reset all game states
		reset_game_state()
		
		# Clean up UI
		UI.game_over.hide()
		UI.game_over.modulate.a = 0.0
		for child in UI.game_over.get_children():
			if child.name == "CreditsMenu" or child.name.begins_with("@Control"):
				child.queue_free()
		
		# Load first level
		get_tree().call_deferred("change_scene_to_file", "res://scenes/Floor0LayoutTest.tscn")
		await get_tree().process_frame
		UI.start_menu.show()
