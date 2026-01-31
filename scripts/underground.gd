extends Node2D

@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var object_layer: TileMapLayer = $ObjectLayer
var player = null
var center_map_pos = Vector2.ZERO

func _ready() -> void:
	Global.loaded_chunks.clear()
	
	Global.current_world_id = "underground"
	MiningManager.current_tilemap = object_layer

	tile_map.generate()

	spawn_player_at_center()
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("Player")
	
	DataManager.spawn_entity("mole_boss", player.global_position - Vector2(80, 80))

func _physics_process(_delta: float) -> void:
	if player:
		Global.update_chunks(object_layer)
		
func spawn_player_at_center():
	@warning_ignore("integer_division")
	var center_world_pos = Global.center_world_pos
	center_map_pos = tile_map.map_to_local(center_world_pos)
	DataManager.spawn_player(center_world_pos)
