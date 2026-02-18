extends Button

var world_name: String = ""

func _on_pressed() -> void:
	AudioManager.play_sfx("menu_click")
	Signals.play_world.emit(world_name)
