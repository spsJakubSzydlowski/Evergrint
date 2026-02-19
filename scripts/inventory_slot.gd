extends PanelContainer

signal slot_clicked(index, slot_ui)

var slot_index = -1

func _gui_input(event: InputEvent) -> void:
	if Global.is_player_dead or Global.world_name == "":
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(slot_index, self)
