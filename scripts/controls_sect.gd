extends Control

@onready var control_grid: GridContainer = $control_grid
var row_scene = preload("res://scenes/UI/change_control_row.tscn")

@onready var audio: Control = $"../audio"
@onready var controls: Control = $"."

func play_click():
	AudioManager.play_sfx("menu_click")

func _on_visibility_changed() -> void:
	for child in control_grid.get_children():
		child.queue_free()
	
	if visible:
		var all_keys = Controls.controls.keys()
		
		for n in all_keys.size():
			var setting_key = all_keys[n]
			var input_index = Controls.controls[setting_key]
			
			var row = row_scene.instantiate()
			
			row.setting_id = setting_key
			row.setting_name = Controls.control_names[n]
			row.button_index = input_index
			
			control_grid.add_child(row)
		
	Signals.change_controls.emit()
	
func _on_done_button_pressed() -> void:
	play_click()
	SettingsManager.save_settings()
	Signals.switch_to_section.emit("menu")

func _on_button_mouse_entered(button):
	if get_node(button).button_pressed: return

	get_node(button).set("theme_override_constants/outline_size", 0)

func _on_button_mouse_exited(button):
	if get_node(button).button_pressed: return
	
	get_node(button).set("theme_override_constants/outline_size", 4)
