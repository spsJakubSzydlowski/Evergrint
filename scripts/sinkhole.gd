extends Area2D

@export_file("*.tscn") var target_scene: String

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		change_level()
		
func change_level():
	if target_scene == "":
		print("ERROR: Scene path is not set")
		
		get_tree().change_scene_to_file(target_scene)
