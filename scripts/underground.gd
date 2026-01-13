extends Node2D

func _ready() -> void:
	DataManager.spawn_player(Global.player_pos)
