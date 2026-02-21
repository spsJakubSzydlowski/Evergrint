extends Control

@onready var done_button: Button = $done_button
@onready var sound_label: Label = $MarginContainer/VBoxContainer/sound_container/sound_label
@onready var sound_slider: HSlider = $MarginContainer/VBoxContainer/sound_container/sound_slider

func play_click():
	AudioManager.play_sfx("menu_click")

func _ready() -> void:
	var value = SettingsManager.current_settings.get("sound_volume")
	sound_label.text = "Sound: " + str(int(value)) + "%"
	sound_slider.value = value

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		if not get_parent().visible:
			visible = false

func _on_sound_slider_value_changed(value: float) -> void:
	sound_label.text = "Sound: " + str(int(value)) + "%"
	SettingsManager.update_setting("sound_volume", int(value))
	
	if sound_slider.has_focus() and int(value) % 6 == 0:
		AudioManager.play_sfx("slider_ratch")

func _on_done_button_pressed() -> void:
	play_click()
	visible = false
