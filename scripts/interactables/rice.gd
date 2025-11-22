extends Readable

const GRAB_RICE = preload("uid://wagh7o1uv3y7")

func interact() -> void:
	super.interact()
	player.has_rice = true
	AudioManager.play_audio(GRAB_RICE)
	SignalBus.rice_picked_up.emit()
	# update ui (on player end)
