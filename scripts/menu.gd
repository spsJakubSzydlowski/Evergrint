extends CanvasLayer

@onready var difficulties: Control = $difficulties
@onready var start_button: Button = $start_button

func _on_button_pressed() -> void:
	start_button.visible = false
	difficulties.visible = true
	
func _on_easy_button_pressed() -> void:
	Global.current_difficulty = Global.Difficulty.EASY
	Global.set_difficulty("easy")
	start_game()

func _on_hard_button_pressed() -> void:
	Global.current_difficulty = Global.Difficulty.HARD
	Global.set_difficulty("hard")
	start_game()
	
func start_game():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
