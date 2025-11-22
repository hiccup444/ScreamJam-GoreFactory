class_name DialogueTester
extends Node

## Utility class to test dialogue resources sequentially

var dialogue_files: Array[DialogueData] = []
var current_index: int = 0
var dialogue_path: String = "res://resources/dialogue/subtitleAudioLink/en/"

func _ready() -> void:
	load_all_dialogue_files()

func load_all_dialogue_files() -> void:
	"""Load all DialogueData resources from the specified directory."""
	dialogue_files.clear()
	current_index = 0
	
	var dir = DirAccess.open(dialogue_path)
	if not dir:
		push_error("DialogueTester: Failed to open directory: " + dialogue_path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Only load .tres files
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = dialogue_path + file_name
			var resource = load(full_path)
			
			# Check if it's a DialogueData resource
			if resource is DialogueData:
				dialogue_files.append(resource)
				print("Loaded dialogue: " + file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort alphabetically for consistent order
	dialogue_files.sort_custom(_sort_by_path)
	
	print("DialogueTester: Loaded " + str(dialogue_files.size()) + " dialogue files")
	if dialogue_files.size() > 0:
		print("Ready to test! Press Page Up to cycle through dialogues.")

func _sort_by_path(a: DialogueData, b: DialogueData) -> bool:
	"""Sort dialogue files alphabetically by resource path."""
	return a.resource_path < b.resource_path

func play_next_dialogue() -> void:
	"""Play the next dialogue in the sequence."""
	if dialogue_files.is_empty():
		print("DialogueTester: No dialogue files loaded!")
		return
	
	var dialogue = dialogue_files[current_index]
	
	# Display info
	var file_name = dialogue.resource_path.get_file()
	print("\n[" + str(current_index + 1) + "/" + str(dialogue_files.size()) + "] Playing: " + file_name)
	if dialogue.speaker_name:
		print("Speaker: " + dialogue.speaker_name)
	
	# Play the dialogue
	AudioManager.play_dialogue_with_subtitle(dialogue)
	
	# Move to next index (wrap around)
	current_index = (current_index + 1) % dialogue_files.size()
	
	if current_index == 0:
		print("\n--- Reached end of dialogue list, wrapping to beginning ---\n")

func play_previous_dialogue() -> void:
	"""Play the previous dialogue in the sequence."""
	if dialogue_files.is_empty():
		print("DialogueTester: No dialogue files loaded!")
		return
	
	# Move back two steps (since we increment after playing)
	current_index = (current_index - 2) % dialogue_files.size()
	if current_index < 0:
		current_index += dialogue_files.size()
	
	play_next_dialogue()

func reset_to_beginning() -> void:
	"""Reset to the first dialogue."""
	current_index = 0
	print("DialogueTester: Reset to beginning")

func get_current_info() -> String:
	"""Get info about the current dialogue."""
	if dialogue_files.is_empty():
		return "No dialogues loaded"
	
	return str(current_index + 1) + "/" + str(dialogue_files.size())
