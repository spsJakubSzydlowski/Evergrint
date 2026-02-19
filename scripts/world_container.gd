extends Button

var world_name: String = ""
var last_played: String = ""
const WORLD_BUTTON_GROUP = preload("uid://blg0026c1didl")

func _ready() -> void:
	button_group = WORLD_BUTTON_GROUP
	self.connect("gui_input", _on_input)

func _on_input(event):
	if event is InputEventMouseButton and event.is_pressed():
		if event.is_double_click():
			Signals.play_world.emit(world_name)

func _on_toggled(toggled_on: bool) -> void:
	AudioManager.play_sfx("menu_click")
	if toggled_on:
		Signals.select_world.emit(world_name)
	else:
		Signals.select_world.emit("")
