extends Node2D

@onready var ground_layer: TileMapLayer = $ground_layer
@onready var object_layer: TileMapLayer = $ObjectLayer
var player = null

var astar: AStarGrid2D

func _ready() -> void:
	Global.loaded_chunks.clear()
	
	Global.current_world_id = "underground"
	Global.current_tilemap = ground_layer
	MiningManager.current_tilemap = object_layer

	ground_layer.generate()
	
	astar = AStarGrid2D.new()
	astar.region = Rect2i(-1000, -1000, 2000, 2000)
	astar.cell_size = Vector2(16, 16)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar.update()

	spawn_player_at_center()
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	if player:
		Global.update_chunks(object_layer)

func spawn_player_at_center():
	var center_world_pos = Global.center_world_pos
	var center_map_pos = ground_layer.map_to_local(center_world_pos)
	
	await get_tree().process_frame
	
	DataManager.spawn_player(center_map_pos)
