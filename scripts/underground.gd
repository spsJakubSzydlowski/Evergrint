extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var object_layer: TileMapLayer = $ObjectLayer
var player = null

func _ready() -> void:
	Global.loaded_chunks.clear()
	
	Global.current_world_id = "underground"
	Global.current_tilemap = tile_map
	MiningManager.current_tilemap = object_layer

	tile_map.generate()

	spawn_player_at_center()
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	if player:
		Global.update_chunks(object_layer)

func spawn_player_at_center():
	var center_world_pos = Global.center_world_pos
	var center_map_pos = tile_map.map_to_local(center_world_pos)
	
	await get_tree().process_frame
	
	DataManager.spawn_player(center_map_pos)
