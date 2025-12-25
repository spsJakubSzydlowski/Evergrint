extends Node2D

func _ready():
	await get_tree().create_timer(0.1).timeout
	DataManager.get_item("red_apple")
	initialize("red_apple")
	
func initialize(item_id: String):
	var data = DataManager.db_data.get(item_id)
	if data == null:
		print("Item with id: " + item_id + " wasnt found")
		return
