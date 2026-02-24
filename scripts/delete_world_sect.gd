extends Control

@onready var delete_world_label: Label = $delete_world_label

var selected_world_name: String

func _ready() -> void:
	Signals.select_world.connect(_on_select_world)
	Signals.delete_world.connect(_on_delete_world)

func play_click():
	AudioManager.play_sfx("menu_click")

func _on_yes_button_pressed() -> void:
	play_click()
	Signals.delete_world.emit(selected_world_name)
	
func _on_no_button_pressed() -> void:
	play_click()
	Signals.switch_to_section.emit("worlds")

func _on_select_world(world_name):
	selected_world_name = world_name
	delete_world_label.text = "Delete world " + str(world_name) + "?"

func _on_delete_world(_world_name):
	SaveManager.delete_world(selected_world_name)
	var worlds_list = SaveManager.get_all_worlds()

	if worlds_list.is_empty():
		Signals.switch_to_section.emit("menu")
	else:
		Signals.switch_to_section.emit("worlds")
	
func _on_button_mouse_entered(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 0)

func _on_button_mouse_exited(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 4)
