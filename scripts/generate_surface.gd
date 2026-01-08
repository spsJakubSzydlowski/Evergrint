extends TileMapLayer

var river_noise = FastNoiseLite.new()
var world_width = 200
var world_height = 200

var tree_count = 800

func _ready() -> void:
	while not DataManager.is_loaded:
		await get_tree().create_timer(0.1).timeout

	river_noise.seed = randi() + 1
	river_noise.frequency = 0.001
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_surface()
	spawn_trees()
	
func generate_surface():
	var grass_tiles : Array[Vector2i] = []
	var water_tiles : Array[Vector2i] = []
	
	for x in range(world_width):
		for y in range(world_height):
			var river_val = river_noise.get_noise_2d(x, y)
			
			if abs(river_val) < 0.01:
				water_tiles.append(Vector2i(x, y))
			elif abs(river_val) < 0.10:
				grass_tiles.append(Vector2i(x, y))
			else:
				grass_tiles.append(Vector2i(x, y))
					
	if grass_tiles.size() > 0:
		self.set_cells_terrain_connect(grass_tiles, 0, 0, false)
		
	for pos in water_tiles:
		self.set_cell(pos, 0, Vector2i(0, 2))
		
func spawn_trees():
	var all_cells = get_used_cells()
	var tree_cells = []
	var spawned = 0

	while spawned < tree_count:
		var random_map_pos = all_cells.pick_random()
		var world_pos = map_to_local(random_map_pos)
		
		var tile_data = get_cell_tile_data(random_map_pos)
		
		var rect = get_used_rect()
		var center_map_pos = rect.position + (rect.size / 2)
		
		if random_map_pos == center_map_pos:
			return
		
		if tile_data and tile_data.get_custom_data("trees") and not tree_cells.has(random_map_pos):
			var tree = DataManager.spawn_resource("oak_tree", world_pos)
			tree_cells.append(random_map_pos)
			if tree:
				if randf() > 0.5:
					var rand_size = randf_range(0.9, 1.1)
					tree.scale = Vector2(rand_size, rand_size)
					tree.scale.x *= -1
			spawned += 1
