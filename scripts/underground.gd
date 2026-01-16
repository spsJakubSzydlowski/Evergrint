extends Node2D

@onready var object_layer: TileMapLayer = $ObjectLayer
var center_map_pos = Vector2.ZERO

func _ready() -> void:
	Global.chunks.clear()
	
	if object_layer:
		var rect = object_layer.get_used_rect()
		center_map_pos = rect.position + (rect.size / 2)
		
	DataManager.spawn_player(object_layer.map_to_local(center_map_pos))
	
	await get_tree().process_frame
