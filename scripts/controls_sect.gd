extends Control

@onready var control_grid: GridContainer = $control_grid
var row_scene = preload("res://scenes/UI/change_control_row.tscn")
var are_you_sure_scene = preload("res://scenes/UI/menu/are_you_sure_sect.tscn")

@onready var audio: Control = $"../audio"


func _ready() -> void:
	Signals.reset_keybinds.connect(_on_reset_keybinds)

func play_click():
	AudioManager.play_sfx("menu_click")

func _on_visibility_changed() -> void:
	if not control_grid:
		return
		
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
	if Global.world_name: get_parent().queue_free()
	else: Signals.switch_to_section.emit("menu")

func _on_button_mouse_entered(button):
	if get_node(button).button_pressed: return

	get_node(button).set("theme_override_constants/outline_size", 0)

func _on_button_mouse_exited(button):
	if get_node(button).button_pressed: return
	
	get_node(button).set("theme_override_constants/outline_size", 4)

func _on_reset_button_pressed() -> void:
	Enums.current_menu_action = Enums.MenuActions.RESET_BINDS
	if Global.world_name:
		var are_you_sure = are_you_sure_scene.instantiate()
		get_parent().get_parent().add_child(are_you_sure)
		get_parent().queue_free()
	else: Signals.switch_to_section.emit("are_you_sure")
	

func _on_reset_keybinds():
	Controls.controls = Controls.default_controls.duplicate()
