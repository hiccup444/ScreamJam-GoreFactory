class_name SettingsMenu
extends Control

@onready var locale_options_button: OptionButton = %LocaleOptionsButton
@onready var subtitles_toggle: CheckButton = %SubtitlesToggle
@onready var back_button: Button = %BackButton
@onready var sensitivity_slider: HSlider = %SensitivitySlider

var map: Dictionary = {
	"English": "en",
	"繁體中文": "zh", # traditional
	"简体中文": "zh_TW" # simplified
}

var on_close: Callable

# Subtitle setting - defaults to true
var subtitles_enabled: bool = true

func _ready() -> void:
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if not locale_options_button:
		push_warning("SettingsMenu: locale_options_button is null")
		return
	# Populate the dropdown from the map
	locale_options_button.clear()
	for language_name in map.keys():
		locale_options_button.add_item(language_name)
	
	# Set dropdown to match current locale
	var current_locale = TranslationServer.get_locale()
	var index = 0
	for language_name in map.keys():
		if map[language_name] == current_locale:
			locale_options_button.select(index)
			break
		index += 1
	
	# Load subtitle setting
	subtitles_enabled = _load_subtitle_setting()
	if subtitles_toggle:
		subtitles_toggle.button_pressed = subtitles_enabled
		subtitles_toggle.toggled.connect(_on_subtitles_toggled)
	
	locale_options_button.item_selected.connect(on_locale_option_selected)
	back_button.pressed.connect(_on_back_button_pressed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_slider_changed)

func on_locale_option_selected(_index: int) -> void:
	var selected_text = locale_options_button.text
	var locale_code = map[selected_text]
	TranslationServer.set_locale(locale_code)
	get_tree().root.propagate_notification(NOTIFICATION_TRANSLATION_CHANGED)

func _on_sensitivity_slider_changed(value: float) -> void:
	SignalBus.sensitivity_changed.emit(value)

func _on_subtitles_toggled(enabled: bool) -> void:
	subtitles_enabled = enabled
	_save_subtitle_setting(enabled)

func _on_back_button_pressed() -> void:
	if on_close:
		on_close.call()

func _save_subtitle_setting(enabled: bool) -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("accessibility", "subtitles_enabled", enabled)
	config.save("user://settings.cfg")

func _load_subtitle_setting() -> bool:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		return true  # Default to enabled
	return config.get_value("accessibility", "subtitles_enabled", true)

# Static method to check if subtitles are enabled from anywhere
static func are_subtitles_enabled() -> bool:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		return true  # Default to enabled
	return config.get_value("accessibility", "subtitles_enabled", true)
