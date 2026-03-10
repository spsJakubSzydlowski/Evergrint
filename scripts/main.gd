extends Node2D

var player = null
@onready var tile_map: TileMapLayer = $ground_layer
@onready var object_layer: TileMapLayer = $ObjectLayer
@onready var water_layer: TileMapLayer = $water_layer
@onready var entity_spawn_timer: Timer = $EntitySpawnTimer

@export var max_entities : int = 20

var astar: AStarGrid2D

func _ready() -> void:
	if not DataManager.is_loaded:
		await DataManager.database_ready
	
	entity_spawn_timer.wait_time = 10.0
	
	Global.current_world_id = "surface"
	Global.current_tilemap = tile_map
	MiningManager.current_tilemap = object_layer
	Inventory.update_inventory()
	
	astar = AStarGrid2D.new()
	astar.region = Rect2i(-1000, -1000, 2000, 2000)
	astar.cell_size = Vector2(16, 16)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
	astar.update()
	
	tile_map.generate()
	
	if Global.first_time_generation:
		
		await spawn_player_at_center()
		player = get_tree().get_first_node_in_group("Player")
		for i in range(10):
			Inventory.add_item("wooden_sword")
			Inventory.add_item("wooden_axe")
			Inventory.add_item("wooden_pickaxe")
		
		Global.first_time_generation = false

	else:
		await spawn_player_at_center()
		player = get_tree().get_first_node_in_group("Player")
		
	spawn_entity(true)

func _physics_process(_delta: float) -> void:
	if player:
		Global.update_chunks(object_layer)

func spawn_entity(first_enemy = false) -> void:
	var current_enemy_count = get_tree().get_nodes_in_group("Entity").size()
	var spawn_pos = Vector2.ZERO
	var attempts = 0
	var found_valid_spot = false
	var final_biome = -1
	
	var new_wait_time = 2.0 + (current_enemy_count * 0.5)
	
	entity_spawn_timer.wait_time = clamp(new_wait_time, 2.0, 12.0)
	
	if current_enemy_count >= max_entities or not player:
		return
	
	while not found_valid_spot and attempts < 20:
		attempts += 1
		var random_angle = randf() * 2 * PI
		var distance
		if first_enemy:
			distance = randf_range((get_viewport_rect().size.x / 2), (get_viewport_rect().size.x / 1.5))
		else:
			distance = randf_range((get_viewport_rect().size.x), (get_viewport_rect().size.x) + 100)

		var offset = Vector2(cos(random_angle), sin(random_angle)) * distance

		spawn_pos = player.global_position + offset
		
		var map_pos = tile_map.local_to_map(spawn_pos)

		if not astar.is_point_solid(map_pos):
			final_biome = tile_map.get_biome_enum(map_pos.x, map_pos.y)
			found_valid_spot = true

	if found_valid_spot:
		var possible_to_spawn = []
		
		for enemy_id in DataManager.get_all_entities():
			var entity_data = DataManager.get_full_entity_data(enemy_id)
			
			var entity_spawn_biome = entity_data.get("spawn_biome")
			if entity_spawn_biome == null: continue
			
			if int(entity_spawn_biome) == int(final_biome):
				possible_to_spawn.append(enemy_id)
			
		if possible_to_spawn.size() > 0:
			var choosen_id = possible_to_spawn.pick_random()
			await DataManager.spawn_entity(choosen_id, spawn_pos)
	
func spawn_player_at_center()-> void:
	Global.update_chunks(object_layer)
	await get_tree().process_frame
	
	var center_world_pos = Global.center_world_pos
	var center_map_pos = tile_map.map_to_local(center_world_pos)
	DataManager.spawn_player(center_map_pos)

func _on_timer_timeout() -> void:
	spawn_entity()
