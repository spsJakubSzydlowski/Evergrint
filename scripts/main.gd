extends Node2D

func _ready():
	await get_tree().create_timer(0.1).timeout
	DataManager.spawn_item("red_apple", Vector2(250, 200))
	DataManager.spawn_item("red_apple", Vector2(350, 200))
	DataManager.spawn_item("red_apple", Vector2(200, 200))
	DataManager.spawn_item("green_apple", Vector2(250, 150))
	DataManager.spawn_item("wooden_sword", Vector2(350, 100))
