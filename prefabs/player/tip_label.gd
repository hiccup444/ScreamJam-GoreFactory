extends Label

var has_picked_up_rice: bool = false
var talisman_picked_up: bool = false
var waiting_for_talisman_dialogue: bool = false

func _ready() -> void:
	hide()
	SignalBus.talisman_picked_up.connect(_on_talisman_picked_up)
	SignalBus.talisman_activated.connect(func(): hide())
	
	SignalBus.rice_picked_up.connect(func():
		if has_picked_up_rice: return
		has_picked_up_rice = true
		text = tr("FThrowRice")
		show()
	)
	SignalBus.rice_thrown.connect(func(_pos): hide())
	
	AudioManager.dialogue_finished.connect(_on_dialogue_finished)
	
	visibility_changed.connect(func(): 
		if visible:
			await get_tree().create_timer(15, false).timeout
			hide()
	)

func _on_talisman_picked_up() -> void:
	talisman_picked_up = true
	waiting_for_talisman_dialogue = true

func _on_dialogue_finished() -> void:
	if waiting_for_talisman_dialogue and talisman_picked_up:
		waiting_for_talisman_dialogue = false
		text = tr("ClickToUseTalisman")
		show()
