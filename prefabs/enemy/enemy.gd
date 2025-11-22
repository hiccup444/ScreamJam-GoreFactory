class_name Enemy
extends CharacterBody3D

var JIANGSHI_MAT: StandardMaterial3D = preload("uid://01obhaya6nlk")

@onready var state_machine: StateMachine = %StateMachine
@onready var nav_agent: NavigationAgent3D = %NavAgent

@onready var player_detection_area: Area3D = %PlayerDetectionArea
@onready var player_detection_ray: RayCast3D = %PlayerDetectionRay
@onready var enemy_attack_area: Area3D = %EnemyAttackArea
@onready var player_pos_anim_node: Node3D = %PlayerPosAnimNode

@onready var animation_player: AnimationPlayer = $Monster/AnimationPlayer
@onready var noise_player: AudioStreamPlayer3D = %NoisePlayer

@export var RUN_SPEED: float = 3.5
@export var WALK_SPEED: float = 2.5
@export var STALK_SPEED: float = 1.5
@export var wandering_nav_points_parent: Node3D
@export var danger_area_tp_point: Node3D

var player: Player
var cur_speed: float = 5.0
var wandering_nav_points: Array[Node3D]
var is_omniscient: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	#JIANGSHI_MAT.stencil_color.a = 0
	set_see_thru_walls(false)
	if wandering_nav_points_parent:
		for child in wandering_nav_points_parent.get_children():
			wandering_nav_points.append(child)
	
	enemy_attack_area.body_entered.connect(on_player_in_attack_range)
	
	SignalBus.rice_thrown.connect(on_rice_thrown)
	
	SignalBus.entered_danger_zone.connect(func(): 
		if is_omniscient or state_machine.state.name == "Chasing": return
		is_omniscient = true
		state_machine.state.finished.emit("Chasing")
		if randf() < 0.3: AudioManager.play_audio(AudioManager.SCREAMS)
		if danger_area_tp_point:
			global_position = danger_area_tp_point.global_position
	)
	SignalBus.exited_danger_zone.connect(func(): is_omniscient = false)
	
	SignalBus.entered_safe_zone.connect(func(): 
		player.is_safe = true
	)
	SignalBus.exited_safe_zone.connect(func(): 
		player.is_safe = false
		if player.talisman_active:
			SignalBus.talisman_activated.emit()
	)

func _physics_process(delta: float) -> void:
	if state_machine.state.name == EnemyState.DYING: return
	if not nav_agent.is_navigation_finished():
		var destination: Vector3 = nav_agent.get_next_path_position()
		var local_destination: Vector3 = destination - global_position
		var direction: Vector3 = local_destination.normalized()
		
		if not global_transform.origin.is_equal_approx(destination):
			# Get target rotation from destination
			var target_transform = global_transform.looking_at(destination, Vector3.UP)
			var target_rotation = target_transform.basis.get_euler().y
			# Smoothly interpolate to target rotation
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * 5.0)
		
		velocity = direction * cur_speed
	else:
		velocity = Vector3.ZERO
	
	rotation.x = 0
	rotation.z = 0
	move_and_slide()

func can_see_player() -> bool:
	if not player_detection_area.monitoring: return false
	if player in player_detection_area.get_overlapping_bodies():
		player_detection_ray.look_at(player.HEAD.global_position)
		if player_detection_ray.is_colliding():
			if player_detection_ray.get_collider() is Player:
				return true
	return false

func set_nav_point(dest: Vector3) -> void:
	nav_agent.target_position = dest

func get_closest_nav_point_to_player() -> Vector3:
	var closest_node: Node3D = wandering_nav_points[0]
	for i: Node3D in wandering_nav_points:
		if i.global_position.distance_to(player.global_position) < closest_node.global_position.distance_to(player.global_position):
			closest_node = i
	return closest_node.global_position

func go_to_random_destination() -> void:
	if not wandering_nav_points: return
	nav_agent.target_position = wandering_nav_points.pick_random().global_position

func go_to_dest_closest_to_player() -> void:
	if randf() < 0.2 and global_position.distance_to(player.global_position) < 40:
		AudioManager.play_dialogue_with_subtitle(AudioManager.WHAT_WAS_THAT)
	
	nav_agent.target_position = get_closest_nav_point_to_player()

func set_see_thru_walls(value: bool = true) -> void:
	var env: WorldEnvironment = get_tree().get_first_node_in_group("WorldEnvironment")
	var color: Color = Color(2.208, 4.449, 1.299)
	var tween = get_tree().create_tween().set_parallel()
	tween.tween_property(JIANGSHI_MAT, "stencil_color", color if value else Color.TRANSPARENT, 1)
	tween.tween_property(env, "environment:adjustment_contrast", 1.5 if value else 1.0, 1)

func on_player_in_attack_range(_body: Node3D) -> void:
	state_machine.state.finished.emit("Attacking")
	player.velocity = Vector3.ZERO
	player.immobile = true
	player.head_locked = true
	
	player.HEAD.look_at(global_position)
	look_at(player.global_position)

	player.animation_tree.active = false
	player.cinematic_camera.current = true
	animation_player.play("Anim-Monster-KillA")
	player.animation_player.play("Anim-Player-DeathA")
	await player.animation_player.animation_finished
	SignalBus.player_killed.emit()

func on_rice_thrown(pos: Vector3) -> void:
	if state_machine.state.name == "Dying": return
	if state_machine.state.name == "Ricing": return
	if global_position.distance_to(player.global_position) > 40:
		global_position = get_closest_nav_point_to_player()
	nav_agent.target_position = pos
	state_machine.state.finished.emit("Ricing")
