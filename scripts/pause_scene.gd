extends CanvasLayer

var menu = "res://scenes/UI/menu.tscn"

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		toggle_menu()

func play_click():
	AudioManager.play_sfx("menu_click")

func toggle_menu():
	visible = not visible
	
	if visible:
		get_tree().paused = true
	else:
		get_tree().paused = false

func _on_button_mouse_entered(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 0)

func _on_button_mouse_exited(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 4)

func _on_resume_button_pressed() -> void:
	play_click()
	toggle_menu()

func _on_savequit_button_pressed() -> void:
	play_click()
	get_tree().paused = false
	SceneChanger.change_scene_save_game(menu)
