extends AnimationPlayer

@export var skip: bool = false

const WAKE_UP = preload("uid://tj1s1sovhofp")
const FUCKFUCKFUCK = preload("uid://bcgdm5oehd15m")
const JUMPSCARE_REACTION = preload("uid://binnfinht4rrw")
const CHAINS_SOUND = preload("uid://dr8i6rgxil883")
const WAKE_UP_AUDIO = preload("uid://c57w7vadarnnv")

@onready var escape_progress_bg: Control
@onready var escape_progress_bar: ProgressBar
@onready var escape_progress_text: RichTextLabel

var player: Player
var env: WorldEnvironment

var progress_decay_rate: float = 10
var current_progress: float = 0.0
var chains_audio_player: AudioStreamPlayer
var wake_up_audio_player: AudioStreamPlayer
var is_waiting_for_escape: bool = false
var fade_timer: SceneTreeTimer = null
var shake_intensity: float = 0.0
var target_volume: float = 0.0
var current_volume: float = 0.0
var last_press_time: float = 0.0
var press_speed: float = 0.0
var lean_offset: float = 0.0
var base_head_rotation: Vector3 = Vector3.ZERO
var assist_timer_started: bool = false
var assist_start_time: float = 0.0
var next_assist_check: float = 10.0

func _ready() -> void:
	env = get_tree().get_first_node_in_group("WorldEnvironment")
	player = get_tree().get_first_node_in_group("Player")
	if skip: return
	env.environment.tonemap_exposure = 0
	
	precompile_shaders()
	
	# Get the progress bar UI elements
	if player.game_ui.get_node_or_null("%EscapeProgressBarBG"):
		escape_progress_bg = player.game_ui.get_node("%EscapeProgressBarBG")
		escape_progress_bar = player.game_ui.get_node("%EscapeProgressBar")
		escape_progress_text = player.game_ui.get_node("%EscapeProgressText")
		
		escape_progress_bar.max_value = 100.0  # normalized 0–100 range
		escape_progress_bar.value = 0
		escape_progress_bg.modulate.a = 0
		escape_progress_bg.visible = false
	
	# Create audio player for chains
	chains_audio_player = AudioStreamPlayer.new()
	chains_audio_player.stream = CHAINS_SOUND
	chains_audio_player.bus = "SFX"
	add_child(chains_audio_player)
	
	# Create audio player for wake up voice
	wake_up_audio_player = AudioStreamPlayer.new()
	wake_up_audio_player.stream = WAKE_UP_AUDIO
	wake_up_audio_player.bus = "Dialogue"
	add_child(wake_up_audio_player)
	
	SignalBus.game_started.connect(play_intro)
	player.immobile = true
	if GameManager.is_game_started:
		play_intro()

var target_lean: float = 0.0
var current_lean: float = 0.0

func _process(delta: float) -> void:
	if not is_waiting_for_escape:
		return
		# Assist mechanic — reduce decay every 20 seconds after first press
	if assist_timer_started:
		var elapsed := Time.get_ticks_msec() / 1000.0 - assist_start_time
		if elapsed >= next_assist_check:
			progress_decay_rate = max(0.0, progress_decay_rate - 3.0)
			print("Assist triggered. New decay rate:", progress_decay_rate)
			next_assist_check += 10.0

	# Update progress bar
	if escape_progress_bar:
		# Decay progress when not pressing
		current_progress = max(0, current_progress - (progress_decay_rate * delta))
		escape_progress_bar.value = current_progress
	
	# Calculate press speed
	var time_since_press = Time.get_ticks_msec() / 1000.0 - last_press_time
	press_speed = clamp(1.0 - (time_since_press / 0.5), 0.0, 1.0)
	
	# Calculate shake offsets
	var shake_x = 0.0
	var shake_y = 0.0
	var shake_z = 0.0
	
	if shake_intensity > 0:
		shake_x = randf_range(-shake_intensity, shake_intensity) * 0.3
		shake_y = randf_range(-shake_intensity, shake_intensity) * 0.3
		shake_z = randf_range(-shake_intensity, shake_intensity) * 0.3
		
		# Decay shake over time
		shake_intensity = lerp(shake_intensity, 0.0, delta * 3.0)
	
	# Smooth interpolation of lean
	current_lean = lerp(current_lean, target_lean, delta * 8.0)
	
	# Decay target lean back to center when not pressing
	target_lean = lerp(target_lean, 0.0, delta * 2.0)
	
	# Apply rotation as offset from base
	player.HEAD.rotation.x = base_head_rotation.x + shake_x
	player.HEAD.rotation.y = base_head_rotation.y + shake_y + current_lean
	player.HEAD.rotation.z = base_head_rotation.z + shake_z + (current_lean * 0.5)
	
	# Clamp rotations
	player.HEAD.rotation.x = clamp(player.HEAD.rotation.x, base_head_rotation.x - 0.3, base_head_rotation.x + 0.3)
	player.HEAD.rotation.y = clamp(player.HEAD.rotation.y, base_head_rotation.y - 0.4, base_head_rotation.y + 0.4)
	player.HEAD.rotation.z = clamp(player.HEAD.rotation.z, base_head_rotation.z - 0.2, base_head_rotation.z + 0.2)
	
	# Handle wake up audio looping
	if wake_up_audio_player.playing:
		var playback_pos = wake_up_audio_player.get_playback_position()
		if playback_pos >= 11.0:
			wake_up_audio_player.seek(8.0)
	
	# Calculate volume
	if time_since_press < 0.5:
		target_volume = 1.25
	else:
		target_volume = 0.0
	
	current_volume = lerp(current_volume, target_volume, delta * 5.0)
	wake_up_audio_player.volume_db = linear_to_db(current_volume)
	
	if current_volume < 0.01 and wake_up_audio_player.playing:
		wake_up_audio_player.stop()

func _input(event: InputEvent) -> void:
	if not is_waiting_for_escape:
		return
	
	if event.is_action_pressed("jump"): # spacebar
		current_progress = clamp(current_progress + 5.0, 0.0, escape_progress_bar.max_value)
		last_press_time = Time.get_ticks_msec() / 1000.0
		if not assist_timer_started:
			assist_timer_started = true
			assist_start_time = Time.get_ticks_msec() / 1000.0
			next_assist_check = 10.0
		
		# Shake the progress bar UI
		if escape_progress_bg:
			var shake_tween = get_tree().create_tween()
			var original_pos = escape_progress_bg.position
			shake_tween.tween_property(escape_progress_bg, "position", original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
			shake_tween.tween_property(escape_progress_bg, "position", original_pos, 0.05)
		
		# Alternate the target lean left and right
		target_lean = -target_lean if target_lean != 0 else 0.12
		
		# Add subtle shake/wiggle effect
		var base_shake = 0.003
		var speed_multiplier = lerp(1.0, 1.2, press_speed)
		shake_intensity = min(shake_intensity + (base_shake * speed_multiplier), lerp(0.02, 0.04, press_speed))
		
		# Start or maintain wake up audio loop
		if not wake_up_audio_player.playing:
			wake_up_audio_player.play()
			wake_up_audio_player.seek(8.0)
		
		# Play chains sound
		if not chains_audio_player.playing:
			chains_audio_player.volume_db = 0
			chains_audio_player.play()
		else:
			chains_audio_player.stop()
			chains_audio_player.volume_db = 0
			chains_audio_player.play()
		
		# Cancel any existing fade timer
		if fade_timer:
			fade_timer = null
		
		# Start new fade timer
		fade_timer = get_tree().create_timer(0.5)
		fade_timer.timeout.connect(_on_fade_timer_timeout)
		
		# Trigger escape when bar reaches max
		if current_progress >= escape_progress_bar.max_value * 1.0:
			escape_successful()

func precompile_shaders() -> void:
	player.blood_particles.emitting = true
	await get_tree().create_timer(0.1).timeout
	player.blood_particles.emitting = false

func _on_fade_timer_timeout() -> void:
	if chains_audio_player.playing and is_waiting_for_escape:
		var tween = get_tree().create_tween()
		tween.tween_property(chains_audio_player, "volume_db", -80, 0.3)
		await tween.finished
		chains_audio_player.stop()
		chains_audio_player.volume_db = 0

func play_intro() -> void:
	player.animation_tree.active = false
	player.immobile = true
	
	play("intro")
	
	# Only show subtitles if enabled
	if SettingsMenu.are_subtitles_enabled():
		await get_tree().create_timer(0.5).timeout
		if WAKE_UP and WAKE_UP.subtitle_data:
			player.game_ui.subtitle_label.visible = true
			var modified_text = WAKE_UP.subtitle_data.get_display_text().replace("<7000>", "<5000>")
			player.game_ui.subtitle_label.display_subtitle(
				modified_text, 
				WAKE_UP.subtitle_data.characters_per_second,
				WAKE_UP.subtitle_data.shake_rate,
				WAKE_UP.subtitle_data.shake_level
			)
		
		await get_tree().create_timer(12.2787 - 0.5).timeout
		if FUCKFUCKFUCK and FUCKFUCKFUCK.subtitle_data:
			player.game_ui.show_subtitle_resource(FUCKFUCKFUCK.subtitle_data)

	await animation_finished

	# Fade in the escape progress UI
	if escape_progress_bg:
		escape_progress_bg.visible = true
		escape_progress_text.visible = true  # Enable the text
		var fade_tween = get_tree().create_tween()
		fade_tween.tween_property(escape_progress_bg, "modulate:a", 1.0, 0.5)
		await fade_tween.finished

	# Save the base rotation when escape starts
	base_head_rotation = player.HEAD.rotation

	is_waiting_for_escape = true
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func escape_successful() -> void:
	is_waiting_for_escape = false
	
	if escape_progress_bg:
		var fade_tween = get_tree().create_tween()
		fade_tween.tween_property(escape_progress_bg, "modulate:a", 0.0, 0.3)
		await fade_tween.finished
		escape_progress_bg.visible = false

	fade_timer = null
	shake_intensity = 0.0
	target_lean = 0.0

	if wake_up_audio_player.playing:
		var current_pos = wake_up_audio_player.get_playback_position()
		if current_pos >= 8.0 and current_pos < 11.0:
			wake_up_audio_player.volume_db = 0

	var tween = get_tree().create_tween()
	tween.tween_property(chains_audio_player, "volume_db", -80, 0.5)
	await tween.finished
	chains_audio_player.stop()
	chains_audio_player.volume_db = 0

	# Smooth camera/head transition before animation
	var start_quat := Quaternion.from_euler(player.HEAD.rotation)
	var target_quat := Quaternion.from_euler(base_head_rotation)
	var duration := 0.4
	var timer := 0.0

	while timer < duration:
		var t := timer / duration
		var slerped := start_quat.slerp(target_quat, t)
		player.HEAD.rotation = slerped.get_euler()
		timer += get_process_delta_time()
		await get_tree().process_frame

	if SettingsMenu.are_subtitles_enabled():
		if JUMPSCARE_REACTION and JUMPSCARE_REACTION.subtitle_data:
			player.game_ui.show_subtitle_resource(JUMPSCARE_REACTION.subtitle_data)

	play("player_fall")
	await animation_finished

	player.animation_tree.active = true
	player.immobile = false
