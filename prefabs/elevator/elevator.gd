class_name Elevator
extends Node3D

enum START_POS { MIDDLE, BOTTOM }

@export var door_presence_detection_area: Area3D
@export var next_level: PackedScene
@export var root_scene: Node3D
@export var start_position: START_POS = START_POS.MIDDLE

@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var elevator_mesh: MeshInstance3D = %Elevator
@onready var elevator_audio_player: AudioStreamPlayer3D = %ElevatorAudioPlayer
@onready var elevator_light: OmniLight3D = %Elevator_OmniLight3D

var door_opened: bool = false
var player: Player
var player_entered_elevator: bool = false

const LIGHTBULB_LOOPABLE = preload("uid://u6b4apj2nwfr")

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	if door_presence_detection_area:
		door_presence_detection_area.body_entered.connect(_on_player_near_door)
	
	if start_position == START_POS.BOTTOM:
		flicker_light_on_load(elevator_light)
		if player and player.player_model:
			player.player_model.hide()
		set_player_elevator_position.call_deferred()
		animation_player.play("move_bottom_top")
		AudioManager.play(AudioManager.ambience_player, AudioManager.ELEVATOR_LOOPABLE)
		await animation_player.animation_finished
		AudioManager.stop(AudioManager.ambience_player)
		animation_player.play("open_gate")
		AudioManager.play_3d(elevator_audio_player, AudioManager.ELEVATOR_DOOR_OPEN_CLOSE)
		player.reparent(root_scene)

func set_player_elevator_position() -> void:
	player.reparent(elevator_mesh)
	player.position.x = GameManager.player_saved_elevator_pos.x
	player.position.z = GameManager.player_saved_elevator_pos.z
	player.rotation = GameManager.player_saved_rot
	player.reset_head_rot()
	player.HEAD.rotation.x = GameManager.player_saved_head_rot.x
	player.HEAD.rotation.y += GameManager.player_saved_head_rot.y
	
	# If we're loading from a transition, flicker light immediately
	if GameManager.elevator_light_off and elevator_light:
		GameManager.elevator_light_off = false
		await flicker_light_on_load(elevator_light)
	player.player_model.show()

func flicker_light_on_load(light: OmniLight3D) -> void:
	# wait short period
	#await get_tree().create_timer(0.1).timeout
	AudioManager.play_3d(%LightAudio, LIGHTBULB_LOOPABLE)
	# then flicker twice
	for i in 2:
		light.visible = false
		await get_tree().create_timer(0.05).timeout
		light.visible = true
		await get_tree().create_timer(0.1).timeout

func _on_player_near_door(_body: Node3D) -> void:
	if door_opened: return
	door_opened = true
	animation_player.play("open_gate")
	AudioManager.play_3d(elevator_audio_player, AudioManager.ELEVATOR_DOOR_OPEN_CLOSE)
	
	elevator_light.visible = false
	await get_tree().create_timer(0.05).timeout
	elevator_light.visible = true
