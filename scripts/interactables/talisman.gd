extends Readable

func interact() -> void:
	super.interact()
	SignalBus.talisman_picked_up.emit()
	player.has_talisman = true
	
	# Show talisman icon
	if player.get_node_or_null("%TalismanIcon"):
		var icon: TextureRect = player.get_node("%TalismanIcon")
		icon.show()
		icon.get_parent().show()
	
	interactable = false
	hide()
	if player.animation_player.is_playing():
		await player.animation_player.animation_finished
	queue_free()
