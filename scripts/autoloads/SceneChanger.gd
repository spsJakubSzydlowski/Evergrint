extends Node

var loading_screen_scene = preload("res://scenes/UI/loading_screen.tscn")

func change_scene_save_game(path: String):
	var ls = loading_screen_scene.instantiate()
	ls.target_scene_path = path
	
	get_tree().root.add_child(ls)
	
	Global.living_boss = false
