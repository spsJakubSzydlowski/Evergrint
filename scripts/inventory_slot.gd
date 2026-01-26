extends PanelContainer

signal slot_clicked(index)

func _gui_input(event: InputEvent) -> void:
	if Global.is_player_dead:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(get_index())

func _make_custom_tooltip(for_text: String) -> Object:
	if for_text == "":
		return null
		
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rtl.custom_minimum_size = Vector2(150, 0)

	var final_text = for_text
	
	rtl.text = final_text
	return rtl
