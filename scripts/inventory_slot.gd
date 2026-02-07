extends PanelContainer

signal slot_clicked(index, slot_ui)

func _gui_input(event: InputEvent) -> void:
	if Global.is_player_dead:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(get_index(), self)
