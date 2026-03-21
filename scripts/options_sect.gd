extends Control

@onready var audio: Control = $audio
@onready var controls: Control = $controls
@onready var audio_button: Button = $MarginContainer/VBoxContainer/audio_button
@onready var controls_button: Button = $MarginContainer/VBoxContainer/controls_button

func _on_visibility_changed() -> void:
	if not visible: return
	
	audio_button.set_pressed(true)
	audio_button.set("theme_override_constants/outline_size", 0)
	
	audio.visible = true
	controls.visible = false

func _on_button_toggled(toggled_on: bool, button: NodePath) -> void:
	if not toggled_on:
		get_node(button).set("theme_override_constants/outline_size", 4)
		
	if get_node(button) == audio_button:
		controls.visible = false
		audio.visible = true
	else:
		controls.visible = true
		audio.visible = false
