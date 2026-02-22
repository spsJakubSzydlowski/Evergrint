extends Control

@onready var new_game_button: Button = $MarginContainer2/VBoxContainer/new_game_button
@onready var load_game_button: Button = $MarginContainer2/VBoxContainer/load_game_button

var menu = null
var worlds_list

func _ready() -> void:
	menu = get_parent()
	
	worlds_list = SaveManager.get_all_worlds()
	if worlds_list.is_empty():
		load_game_button.disabled = true
	else:
		load_game_button.disabled = false

func play_click():
	AudioManager.play_sfx("menu_click")

func _on_load_game_button_pressed() -> void:
	play_click()
	Signals.switch_to_section.emit("worlds")
	menu.current_action = menu.Actions.LOAD

func _on_new_game_button_pressed() -> void:
	play_click()
	Signals.switch_to_section.emit("create")
	menu.current_action = menu.Actions.CREATE

func _on_options_button_pressed() -> void:
	play_click()
	Signals.switch_to_section.emit("options")

func _on_quit_button_pressed() -> void:
	play_click()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _on_button_mouse_entered(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 0)

func _on_button_mouse_exited(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 4)

func _on_visibility_changed() -> void:
	worlds_list = SaveManager.get_all_worlds()
	if not load_game_button: return
	
	if worlds_list.is_empty():
		load_game_button.disabled = true
	else:
		load_game_button.disabled = false
