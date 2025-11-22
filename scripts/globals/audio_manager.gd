extends Node

signal dialogue_started(dialogue_data: DialogueData)
signal dialogue_finished

var master_volume: float = 1.0
var music_volume: float = 0.5
var sfx_volume: float = 0.5
var dialogue_volume: float = 0.5

var current_music_player: AudioStreamPlayer = null
var dialogue_player: AudioStreamPlayer = null
var ambience_player: AudioStreamPlayer = null
var breathing_player: AudioStreamPlayer = null

var current_dialogue_data: DialogueData = null
var dialogue_paused: bool = false
var dialogue_pause_position: float = 0.0

var stop_tween: Tween

#region Music
const MENU_THEME = preload("uid://b48j4pewqb4y4")
const _80S_POP_THEME = preload("uid://cwviagc6gnx3t")
const CHASE_THEME_LOOPABLE = preload("uid://7vtw75c13pfk")
const AMBIANCE = preload("uid://dveogwvjsu6ot")

#endregion

#region SFX
const UI_CLICKS = preload("uid://bxyuhurt0yexe")
const UI_BUTTON_SELECTION = preload("uid://d01srv74nq6kf")
const UI_SELECTION_HEAVY = preload("uid://c8wbh1blnjrpn")

const ROBOT_ZOMBIE_GROWL_2_ = preload("uid://d0lq02gmg6qg3")
const THERE_YOU_ARE_ROBOT_ZOMBIE = preload("uid://gkpb8hys51ts")

const GRUNTS = preload("uid://lqgo7q6whiw")
const TALISMAN_ACTIVATED = preload("uid://7sgfj62kxdf4")
const ELEVATOR_LOOPABLE = preload("uid://dxsyupr6vkfax")
const ELEVATOR_DOOR_OPEN_CLOSE = preload("uid://c2e2flkvldshf")

const OUT_OF_STAMINA = preload("uid://cos67lbdjc2q3")
const CHASE_BREATHING = preload("uid://cg1ojl13xibuw")
const SNEAK_BREATHING = preload("uid://kuyrg55rheht")

const ITS_CLOSE = preload("uid://mp5jx2e4dsmv")
const IT_SCANS = preload("uid://q36t8mluo5s8")
const WHERE_ARE_MY_CLOTHES = preload("uid://5mmw00ddqt5v")
const WHAT_WAS_THAT = preload("uid://b6enul55jck8s")
const FUCK_YOU = preload("uid://by5fqbwd1d0on")
const FUCKFUCKFUCK = preload("uid://bcgdm5oehd15m")
const HUH = preload("uid://c4cge34t4xnja")
const USE_DETECTOR = preload("uid://hym3n4n0lbbc")

const RICE_THROW_ON_FLOOR = preload("uid://b0rksl3obsu1j")
const ORGAN_SLOSH = preload("uid://btoqe1pqarmbe")

# RANDOMIZERS
const TALISMAN_ACTIVATED_CLOSE = preload("uid://7sgfj62kxdf4")
const RECHARGE_READY_TALISMAN = preload("uid://bwrnsnacy6gu4")
const SCREAMS = preload("uid://cf5ttc6c12xmf")

#endregion

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	current_music_player = AudioStreamPlayer.new()
	current_music_player.bus = "Music"
	add_child(current_music_player)
	
	dialogue_player = AudioStreamPlayer.new()
	dialogue_player.bus = "Dialogue"
	dialogue_player.finished.connect(_on_dialogue_finished)
	add_child(dialogue_player)
	
	breathing_player = AudioStreamPlayer.new()
	breathing_player.bus = "Dialogue"
	add_child(breathing_player)
	
	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "SFX"
	add_child(ambience_player)
	
	play(ambience_player, AMBIANCE)

func _enter_tree() -> void:
	get_tree().node_added.connect(on_node_added)

func _process(_delta: float) -> void:
	# Handle dialogue pausing when game is paused
	if get_tree().paused and not Player.is_reading:
		if dialogue_player.playing and not dialogue_paused:
			# Pause the dialogue
			dialogue_pause_position = dialogue_player.get_playback_position()
			dialogue_player.stop()
			dialogue_paused = true
	elif dialogue_paused and (not get_tree().paused or Player.is_reading):
		# Resume the dialogue
		if current_dialogue_data:
			dialogue_player.play(dialogue_pause_position)
			dialogue_paused = false

func set_volume(mixer: String, volume: float) -> float:
	var bus_idx = AudioServer.get_bus_index(mixer)
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))
	return volume

func play(player: AudioStreamPlayer, stream: AudioStream) -> void:
	if stop_tween:
		stop_tween.kill()
		stop_tween = null
	player.volume_db = 0
	player.stream = stream
	player.play()

func play_3d(player: AudioStreamPlayer3D, stream: AudioStream, mixer: String = "SFX") -> void:
	player.stream = stream
	player.bus = mixer
	player.play()

func stop(player: AudioStreamPlayer, fade_out_t: float = 1) -> void:
	# Stop a specific existing audio player
	stop_tween = get_tree().create_tween()
	stop_tween.tween_property(player, "volume_db", -72, fade_out_t)
	await stop_tween.finished
	player.stop()
	player.volume_db = 0
	
	if player == ambience_player:
		play(ambience_player, AMBIANCE)

# Play dialogue with subtitle
func play_dialogue(stream: AudioStream) -> void:
	play(dialogue_player, stream)

# Play dialogue from a DialogueData resource (audio + subtitle)
func play_dialogue_with_subtitle(dialogue_data: DialogueData) -> void:
	if not dialogue_data or not dialogue_data.is_valid():
		push_error("Invalid dialogue data provided")
		return
	
	# Reset pause state when starting new dialogue
	dialogue_paused = false
	dialogue_pause_position = 0.0
	
	current_dialogue_data = dialogue_data
	dialogue_player.stream = dialogue_data.audio_clip
	dialogue_player.play()
	
	# Emit signal so subtitle manager can display the subtitle
	dialogue_started.emit(dialogue_data)

func play_random_dialogue_with_subtitle(dialogue_data: RandomDialogueData) -> void:
	play_dialogue_with_subtitle(dialogue_data.dialogue_data_list.pick_random())

# Stop current dialogue
func stop_dialogue() -> void:
	if dialogue_player.playing:
		dialogue_player.stop()
		_on_dialogue_finished()
	
	# Reset pause state
	dialogue_paused = false
	dialogue_pause_position = 0.0

func _on_dialogue_finished() -> void:
	current_dialogue_data = null
	dialogue_paused = false
	dialogue_pause_position = 0.0
	dialogue_finished.emit()

func play_audio(file: AudioStream, mixer: String = "SFX", volume: float = 1, pitch: bool = false) -> void:
	# Given a preloaded soundfile, generate an audio stream player, spawn it,
	# load the file, play it, and then destroy the player.
	var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_player.stream = file
	audio_player.bus = mixer
	audio_player.volume_db = linear_to_db(volume)
	add_child(audio_player)
	if pitch:
		audio_player.pitch_scale += randf_range(-0.15, 0.15)
	audio_player.play()
	await audio_player.finished
	remove_child(audio_player)
	audio_player.queue_free()

func play_random(list: Array[AudioStream], volume:= 1.0, player: AudioStreamPlayer3D = null) -> void:
	var track = list.pick_random()
	if player:
		player.stream = track
		player.play()
	else:
		play_audio(track, "SFX", volume)

# Set up button SFX for clicks and hovers automatically.
func on_node_added(node: Node) -> void:
	if node is Button or node is TextureButton:
		node.mouse_entered.connect(on_button_hover)
		node.pressed.connect(on_button_pressed)

func on_button_hover() -> void:
	play_audio(UI_BUTTON_SELECTION)

func on_button_pressed() -> void:
	play_audio(UI_SELECTION_HEAVY)
