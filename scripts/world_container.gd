extends Button

var world_name: String = ""

func _on_pressed() -> void:
	Signals.play_world.emit(world_name)
