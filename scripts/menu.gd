extends CanvasLayer

@onready var difficulties: Control = $difficulties
@onready var menu: Control = $menu

func _on_new_game_button_pressed() -> void:
	menu.visible = false
	difficulties.visible = true
	AudioManager.play_sfx("menu_click")

func _on_load_game_button_pressed() -> void:
	pass

func _on_easy_button_pressed() -> void:
	Global.current_difficulty = Global.Difficulty.EASY
	Global.set_difficulty_mult("easy")
	
	AudioManager.play_sfx("menu_click")
	start_game()

func _on_hard_button_pressed() -> void:
	Global.current_difficulty = Global.Difficulty.HARD
	Global.set_difficulty_mult("hard")
	
	AudioManager.play_sfx("menu_click")
	start_game()
	
func start_game():
	Global.transition_to("surface")
