class_name Player
extends FirstPersonController

const RICE = preload("uid://cuqoh5s4bm3jd")

@export var MAX_STAMINA: float = 8 ## Duration in seconds you can run for
@export var MAX_TALISMAN_TIME: float = 5

@onready var cinematic_camera: Camera3D = %CinematicCamera

@onready var talisman_audio_player: AudioStreamPlayer = $TalismanAudioPlayer
@onready var sfx_audio_player: AudioStreamPlayer = %SFXAudioPlayer

@onready var game_ui: GameUI = $GameUI
@onready var interaction_ray: RayCast3D = %InteractionRay
@onready var player_model: Node3D = %Player
@onready var animation_tree: AnimationTree = %AnimationTree
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var head_ref_tracker: Node3D = %HeadRefTracker

@onready var zone_detection_area: Area3D = %ZoneDetectionArea
@onready var surface_detection_area: Area3D = %SurfaceDetectionArea

@onready var blood_particles: CPUParticles3D = %BloodParticles

@onready var rice_particles: CPUParticles3D = %RiceParticles
@onready var rice_target_node: Node3D = %RiceTargetNode

@onready var talisman_icon = %TalismanIcon
@onready var rice_icon: TextureRect = %RiceIcon

var enemy: Enemy

var has_talisman: bool = false
var has_rice: bool = false
var rice_instance: Node3D = null

var talisman_has_been_used: bool = false
var talisman_active: bool = false
var cur_talisman_stamina: float = MAX_TALISMAN_TIME

var cur_stamina: float = MAX_STAMINA

var is_safe: bool = false
static var is_reading: bool = false

func _ready() -> void:
	super._ready()
	blood_particles.emitting = false
	enemy = get_tree().get_first_node_in_group("Enemy")
	zone_detection_area.area_entered.connect(on_zone_entered)
	zone_detection_area.area_exited.connect(on_zone_exited)
	SignalBus.sensitivity_changed.connect(func(v: float): mouse_sensitivity = v)
	
	SignalBus.rice_picked_up.connect(func(): rice_icon.show(); rice_icon.get_parent().show())
	SignalBus.rice_thrown.connect(func(_v): rice_icon.hide())
	
	# Hide talisman icon initially
	talisman_icon.visible = has_talisman
	rice_icon.visible = has_rice

func _physics_process(delta):
	super._physics_process(delta)
	player_model.rotation.y = HEAD.rotation.y
	HEAD.global_position = head_ref_tracker.global_position
	if not GameManager.is_game_started: return
	
	if HEAD.rotation.x < -1 and not GameManager.has_looked_down and not immobile:
		GameManager.has_looked_down = true
		AudioManager.play_dialogue_with_subtitle(AudioManager.WHERE_ARE_MY_CLOTHES)
	
	handle_stamina(delta)
	handle_talisman_stamina(delta)
	
	if state == "sprinting":
		if not AudioManager.breathing_player.playing:
			AudioManager.play(AudioManager.breathing_player, AudioManager.CHASE_BREATHING)
		animation_tree.set("parameters/Motion/transition_request", "run")
		animation_tree.set("parameters/Walk/blend_position", Vector2(0, current_speed / sprint_speed))
	elif state == "crouching":
		if not AudioManager.breathing_player.playing:
			AudioManager.play(AudioManager.breathing_player, AudioManager.SNEAK_BREATHING)
		animation_tree.set("parameters/Motion/transition_request", "crouch")
		animation_tree.set("parameters/Crouch/blend_position", Vector2(0, current_speed / crouch_speed))
	elif state == "normal" and current_speed > 0.5:
		if AudioManager.breathing_player.playing:
			AudioManager.stop(AudioManager.breathing_player, .6)
		animation_tree.set("parameters/Motion/transition_request", "walk")
		animation_tree.set("parameters/Walk/blend_position", Vector2(get_sideways_v(), current_speed / base_speed))
	else:
		AudioManager.stop(AudioManager.breathing_player)
		animation_tree.set("parameters/Motion/transition_request", "idle")
	
	handle_surface_walking_effects()
	
func _input(event: InputEvent) -> void:
	if not GameManager.is_game_started: return
	if event.is_action_pressed("primary_fire") and has_talisman and cur_talisman_stamina > 0 and not immobile:
		toggle_talisman()
	elif event.is_action_pressed("secondary_interact") and has_rice:
		# Check if looking at shredder - if so, let shredder handle it
		var obj: Interactable = get_looked_at_interactable()
		if obj and obj is Shredder and obj.interactable:
			return  # Let the shredder handle the input
		throw_rice()

func on_zone_exited(area: Area3D) -> void:
	# Safe Area
	if area.get_collision_layer_value(4):
		SignalBus.exited_safe_zone.emit()
	# Danger Area
	if area.get_collision_layer_value(5):
		SignalBus.exited_danger_zone.emit()

func get_sideways_v() -> float:
	var head_basis = HEAD.global_transform.basis
	var right = head_basis.x
	right.y = 0
	right = right.normalized()

	var horizontal_velocity = velocity
	horizontal_velocity.y = 0

	var sideways_amount = right.dot(horizontal_velocity.normalized())
	return sideways_amount

func toggle_talisman() -> void:
	talisman_active = !talisman_active
	enemy.set_see_thru_walls(talisman_active)
	if talisman_active:
		talisman_audio_player.play()
		AudioManager.play_audio(AudioManager.RECHARGE_READY_TALISMAN)
	else:
		AudioManager.stop(talisman_audio_player)
	
	if not talisman_active: return
	
	SignalBus.talisman_activated.emit()
	if not talisman_has_been_used:
		talisman_has_been_used = true
		AudioManager.play_dialogue_with_subtitle(AudioManager.IT_SCANS)
		return
	if global_position.distance_to(enemy.global_position) < 20:
		AudioManager.play_random_dialogue_with_subtitle(AudioManager.TALISMAN_ACTIVATED_CLOSE)
	else:
		if randf() < 0.2:
			AudioManager.play_dialogue_with_subtitle(AudioManager.USE_DETECTOR)
		# TODO: SFX for talisman

func handle_surface_walking_effects() -> void:
	if not surface_detection_area.has_overlapping_areas():
		if sfx_audio_player.playing: sfx_audio_player.stop()
		return
	if sfx_audio_player.stream != AudioManager.ORGAN_SLOSH:
		sfx_audio_player.stream = AudioManager.ORGAN_SLOSH
	if current_speed > 0.2 and not sfx_audio_player.playing:
		sfx_audio_player.play()
	elif current_speed < 0.2 and sfx_audio_player.playing:
		sfx_audio_player.stream_paused = true

func throw_rice() -> void:
	rice_particles.emitting = true
	has_rice = false
	AudioManager.play_audio(AudioManager.RICE_THROW_ON_FLOOR)
	var loc: Vector3 = rice_target_node.global_position
	loc.y = 0
	
	await rice_particles.finished
	rice_instance = RICE.instantiate()
	get_parent().add_child(rice_instance)
	rice_instance.global_position = loc
	
	SignalBus.rice_thrown.emit(loc)

func handle_talisman_stamina(delta: float) -> void:
	if talisman_active:
		cur_talisman_stamina = clampf(cur_talisman_stamina - delta, 0, MAX_TALISMAN_TIME)
		if cur_talisman_stamina <= 0:
			toggle_talisman()
	else:
		cur_talisman_stamina = clampf(cur_talisman_stamina + delta, 0, MAX_TALISMAN_TIME)

func handle_stamina(delta: float) -> void:
	if state == "sprinting" and sprint_enabled:
		cur_stamina = clampf(cur_stamina - delta, 0, MAX_STAMINA)
		if cur_stamina <= 0: 
			sprint_enabled = false
			enter_normal_state()
			AudioManager.play_audio(AudioManager.OUT_OF_STAMINA)
	else:
		cur_stamina = clampf(cur_stamina + delta, 0, MAX_STAMINA)
		if cur_stamina >= MAX_STAMINA: 
			sprint_enabled = true

func on_zone_entered(area: Area3D) -> void:
	# Safe Area
	if area.get_collision_layer_value(4):
		SignalBus.entered_safe_zone.emit()
	# Danger Area
	if area.get_collision_layer_value(5):
		SignalBus.entered_danger_zone.emit()

func get_looked_at_interactable() -> Interactable:
	if not interaction_ray.is_colliding(): return null
	var col := interaction_ray.get_collider()
	if col is not Interactable: return null
	return col

func toggle_bleed() -> void:
	blood_particles.emitting = !blood_particles.emitting
