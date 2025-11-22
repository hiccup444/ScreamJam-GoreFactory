class_name Readable
extends Interactable

@export var readable_entry: ReadableResource

const PAPER_PICKUP = preload("uid://tlmwpiw66wfh")
const WHATS_THIS = preload("res://resources/dialogue/subtitleAudioLink/en/whats this (en).tres")

func interact() -> void:
	super.interact()
	var note: Note = player.game_ui.note
	if readable_entry:
		if get_node_or_null("%InteractableParticles"):
			%InteractableParticles.emitting = false
		AudioManager.play_audio(PAPER_PICKUP)
		
		# 20% chance to play pickup dialogue
		if randf() < 0.2:
			AudioManager.play_dialogue_with_subtitle(WHATS_THIS)
			# Wait for the dialogue to finish before playing item-specific dialogue
			if readable_entry.dialogue:
				await AudioManager.dialogue_finished
		
		note.show_note()
		note.text.text = tr(readable_entry.readable_text)
		if readable_entry.paper_texture:
			note.paper_texture_rect.texture = readable_entry.paper_texture
		if readable_entry.dialogue:
			AudioManager.play_dialogue_with_subtitle(readable_entry.dialogue)
