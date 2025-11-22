class_name DialogueData
extends Resource

## Resource that pairs an audio clip with subtitle data

@export var audio_clip: AudioStream
@export var subtitle_data: SubtitleData
@export var speaker_name: String = ""

func is_valid() -> bool:
	return audio_clip != null and subtitle_data != null
