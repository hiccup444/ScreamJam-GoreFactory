extends VBoxContainer

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var dialogue_slider: HSlider = %DialogueSlider

func _ready() -> void:
	master_slider.value_changed.connect(on_master_volume_changed)
	music_slider.value_changed.connect(on_music_slider_changed)
	sfx_slider.value_changed.connect(on_sfx_slider_changed)
	dialogue_slider.value_changed.connect(on_dialogue_slider_changed)
	
	visibility_changed.connect(sync_slider_values)
	
	sync_slider_values()

func sync_slider_values() -> void:
	AudioManager.set_volume("Master", AudioManager.master_volume)
	AudioManager.set_volume("Music", AudioManager.music_volume)
	AudioManager.set_volume("SFX", AudioManager.sfx_volume)
	AudioManager.set_volume("Dialogue", AudioManager.dialogue_volume)
	
	master_slider.set_value_no_signal(AudioManager.master_volume)
	music_slider.set_value_no_signal(AudioManager.music_volume)
	sfx_slider.set_value_no_signal(AudioManager.sfx_volume)
	dialogue_slider.set_value_no_signal(AudioManager.dialogue_volume)

func on_master_volume_changed(value: float) -> void:
	AudioManager.master_volume = value
	AudioManager.set_volume("Master", value)

func on_music_slider_changed(value: float) -> void:
	AudioManager.music_volume = value;
	AudioManager.set_volume("Music", value)

func on_dialogue_slider_changed(value: float) -> void:
	AudioManager.dialogue_volume = value;
	AudioManager.set_volume("Dialogue", value)

func on_sfx_slider_changed(value: float) -> void:
	AudioManager.sfx_volume = value;
	AudioManager.set_volume("SFX", value)
	AudioManager.play_audio(AudioManager.UI_CLICKS)
