class_name SubtitleData
extends Resource

@export_multiline var text: String = ""
@export var characters_per_second: float = 30.0
@export var auto_hide: bool = false
@export var auto_hide_delay_ms: float = 1000.0  # Delay after typing finishes before hiding
@export var force_interaction: bool = false  # Requires player input to dismiss
@export var require_finished_text: bool = false  # Prevents skipping until typing is complete
@export var allow_interruption: bool = false  # Allow this subtitle to be replaced by another
@export var translation_key: String = ""
@export_group("Shake Effect")
@export var shake_rate: float = 20.0  # Speed of shake animation
@export var shake_level: float = 5.0  # Intensity of shake animation
@export var auto_hide_delay_multipliers: Dictionary = {
	"en": 1.0,
	"zh_TW": 0.8,
	"zh": 0.8
}

func get_adjusted_auto_hide_delay() -> float:
	var locale = TranslationServer.get_locale()
	var multiplier = auto_hide_delay_multipliers.get(locale, 1.0)
	return auto_hide_delay_ms * multiplier
	
func get_display_text() -> String:
	"""Get the text to display, with translation support if key is provided."""
	if translation_key != "":
		return tr(translation_key)
	return text
