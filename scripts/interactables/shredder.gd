class_name Shredder
extends Interactable

@export var ending_cinematic: AnimationPlayer

var interacted: bool = false

func interact() -> void:
	if not ending_cinematic: return
	interactable = false
	interacted = true
	end_game()

func _input(event: InputEvent) -> void:
	# Call parent to handle E key
	super._input(event)
	
	# Don't process if already used
	if interacted or not interactable: return
	
	# Check if player is looking at the shredder
	var obj: Interactable = player.get_looked_at_interactable()
	if obj != self: return
	
	# Allow F (secondary_interact) to also trigger the ending
	if event.is_action_pressed("secondary_interact") and player.has_rice:
		interactable = false
		interacted = true
		end_game()

func end_game() -> void:
	var enemy: Enemy = get_tree().get_first_node_in_group("Enemy")
	enemy.state_machine.state.finished.emit("Dying")
	ending_cinematic.play("ending")
	await ending_cinematic.animation_finished
	SignalBus.game_won.emit()

func _physics_process(_delta: float) -> void:
	interactable = player.has_rice and not interacted
