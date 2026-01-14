extends TileMapLayer

var river_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()
var world_width = 200
var world_height = 200

var center_map_pos

var occupied_cells = []

var player = null

@export var object_layer: TileMapLayer

func _ready() -> void:
	while not DataManager.is_loaded:
		await get_tree().create_timer(0.1).timeout
	
	player = get_tree().get_first_node_in_group("Player")
	
	cave_noise.seed = Global.world_seed + 50
	cave_noise.frequency = 0.05
	
	river_noise.seed = Global.world_seed
	river_noise.frequency = 0.001
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_surface()
	
	var rect = get_used_rect()
	center_map_pos = rect.position + (rect.size / 2)
	
	spawn_starting_ladder()
	
func generate_surface():
	var stone_tiles : Array[Vector2i] = []
	var lava_tiles : Array[Vector2i] = []
	
	for x in range(world_width):
		for y in range(world_height):
			var river_val = river_noise.get_noise_2d(x, y)
			
			if abs(river_val) < 0.01:
				lava_tiles.append(Vector2i(x, y))
			elif abs(river_val) < 0.10:
				stone_tiles.append(Vector2i(x, y))
			else:
				stone_tiles.append(Vector2i(x, y))
	
	if stone_tiles.size() > 0:
		self.set_cells_terrain_connect(stone_tiles, 0, 1, false)
		
	if lava_tiles.size() > 0:
		self.set_cells_terrain_connect(lava_tiles, 0, 3, false)

func spawn_starting_ladder():
	var sinkhole_pos = center_map_pos + Vector2i(10, 10)

	object_layer.set_cell(sinkhole_pos, 2, Vector2i(0, 0))
	
	occupied_cells.append(sinkhole_pos)

func spawn_blocks(x, y, chunk_node):
	var val = cave_noise.get_noise_2d(x, y)
	
	if val > -0.2:
		var map_pos = Vector2i(x, y)
		var tile_data = get_cell_tile_data(map_pos)
	
		if occupied_cells.has(map_pos) or Global.world_changes.get(map_pos) == "removed":
			return
			
		if tile_data and not tile_data.get_custom_data("water") and not occupied_cells.has(map_pos):
			var world_pos = map_to_local(map_pos)
			DataManager.spawn_resource("oak_tree", world_pos, chunk_node)

func _on_chunk_timer_timeout() -> void:
	var player_world_pos = Global.get_player_world_position()
	
	var player_map_pos = local_to_map(player_world_pos)
	
	var cx = floor(player_map_pos.x / float(Global.chunk_size))
	var cy = floor(player_map_pos.y / float(Global.chunk_size))
	
	for x in range(cx - Global.render_distance, cx + Global.render_distance + 1):
		for y in range(cy - Global.render_distance, cy + Global.render_distance + 1):
			Global.load_chunk(x, y, spawn_blocks, object_layer)
	
	Global.unload_chunk(cx, cy)
