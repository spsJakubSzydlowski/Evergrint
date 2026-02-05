extends Node2D

var player = null
@onready var tile_map: TileMapLayer = $TileMapLayer
@onready var object_layer: TileMapLayer = $ObjectLayer

@export var max_entities = 200

func _ready():
	if not DataManager.is_loaded:
		await DataManager.database_ready
	
	Global.current_world_id = "surface"
	MiningManager.current_tilemap = object_layer
	Inventory.update_inventory()
	
	tile_map.generate()
	
	if Global.first_time_generation:
		
		await spawn_player_at_center()
		player = get_tree().get_first_node_in_group("Player")

		DataManager.spawn_item("wooden_sword", player.global_position, false)
		DataManager.spawn_item("wooden_axe", player.global_position, false)
		DataManager.spawn_item("wooden_hammer", player.global_position, false)
		DataManager.spawn_item("wooden_bow", player.global_position, false)
		DataManager.spawn_item("wooden_pickaxe", player.global_position, false)
		for i in range(10):
			DataManager.spawn_item("arrow", player.global_position, false)
			DataManager.spawn_item("head_of_the_burrower", player.global_position, false)
			DataManager.spawn_item("green_apple", player.global_position, false)
		
		Global.first_time_generation = false
	else:
		await spawn_player_at_center()
		player = get_tree().get_first_node_in_group("Player")
		

func _physics_process(_delta: float) -> void:
	if player:
		Global.update_chunks(object_layer)
		
func spawn_entity():
	var current_enemy_count = get_tree().get_nodes_in_group("entity").size()
	var spawn_pos = Vector2.ZERO
	var attempts = 0
	var found_valid_spot = false
	
	if current_enemy_count >= max_entities:
		return
	
	if player:
		while not found_valid_spot and attempts < 20:
			attempts += 1
			var random_angle = randf() * 2 * PI
			var distance = randf_range(get_viewport_rect().end.x, get_viewport_rect().end.x + 200)

			var offset = Vector2(cos(random_angle), sin(random_angle)) * distance

			spawn_pos = player.global_position + offset

			var map_pos = tile_map.local_to_map(spawn_pos)
			var tile_data = tile_map.get_cell_tile_data(map_pos)
			if tile_data and not tile_data.get_custom_data("water"):
				found_valid_spot = true
		
		if found_valid_spot:
			await DataManager.spawn_entity("green_slime", spawn_pos)

func spawn_player_at_center():
	Global.update_chunks(object_layer)
	await get_tree().process_frame
	
	var center_world_pos = Global.center_world_pos
	var center_map_pos = tile_map.map_to_local(center_world_pos)
	DataManager.spawn_player(center_map_pos)

func _on_timer_timeout() -> void:
	spawn_entity()
