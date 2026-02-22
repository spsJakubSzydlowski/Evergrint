extends Button

var world_name: String = ""
var last_played: String = ""
const WORLD_BUTTON_GROUP = preload("uid://blg0026c1didl")

func _ready() -> void:
	Signals.delete_world.connect(_on_world_deleted)
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

func _on_delete_button_pressed() -> void:
	AudioManager.play_sfx("menu_click")
	Signals.select_world.emit(world_name)
	Signals.switch_to_section.emit("delete_world")

func _on_world_deleted(_world_name):
	queue_free()
