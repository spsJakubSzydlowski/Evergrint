extends Node2D

func _ready():
	if not DataManager.is_loaded:
		await DataManager.database_ready

	DataManager.spawn_item("wooden_sword", Vector2(380, 100))
	
	for i in range(10):
		DataManager.spawn_entity("green_slime", Vector2(400 + i * 20, 100))
