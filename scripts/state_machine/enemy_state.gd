class_name EnemyState
extends State

const IDLE = "Idle"
const WANDERING = "Wandering"
const CHASING = "Chasing"
const ATTACKING = "Attacking"
const SEARCHING = "Searching"
const RICING = "Ricing"
const DYING = "Dying"

var player: Player
var enemy: Enemy
var idling: bool

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	enemy = get_tree().get_first_node_in_group("Enemy")
	finished.connect(_on_state_changed)
	SignalBus.talisman_activated.connect(_on_talisman_activated)

func _on_state_changed(state) -> void:
	print("State changed to: ", state)

func _on_talisman_activated() -> void:
	if player.is_safe: return
	if enemy.global_position.distance_to(player.global_position) < 50:
		enemy.nav_agent.target_position = player.global_position
