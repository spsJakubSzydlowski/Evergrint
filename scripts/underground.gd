extends Node2D

func _ready() -> void:
	Global.chunks.clear()
	
	DataManager.spawn_player(Global.player_pos)
	
	await get_tree().process_frame
