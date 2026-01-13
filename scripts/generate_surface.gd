extends TileMapLayer

const GRASS_TERRAIN = 0
const WATER_TERRAIN = 2

var river_noise = FastNoiseLite.new()
var world_width = 200
var world_height = 200

var tree_count = 800
var occupied_cells = []

@export var object_layer: TileMapLayer

func _ready() -> void:
	while not DataManager.is_loaded:
		await get_tree().create_timer(0.1).timeout

	river_noise.seed = Global.world_seed
	river_noise.frequency = 0.001
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_surface()
	await  get_tree().process_frame
	
	notify_runtime_tile_data_update()
	spawn_starting_sinkhole()
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
		self.set_cells_terrain_connect(grass_tiles, 0, GRASS_TERRAIN, false)
		
	if water_tiles.size() > 0:
		self.set_cells_terrain_connect(water_tiles, 0, WATER_TERRAIN, false)
		
func spawn_trees():
	@warning_ignore("integer_division")
	var center_map_pos = Vector2i(world_width / 2, world_height / 2)
	print("Forestification")
	seed(Global.world_seed + 123)
	
	var all_cells = get_used_cells()
	
	var spawned = 0
	var attempts = 0
	var max_attempts = tree_count * 5
	
	if world_width == 0 or world_height == 0:
		print("Error: Map size is 0")
		return
	
	while spawned < tree_count and attempts < max_attempts:
		attempts += 1
		
		var random_map_pos = all_cells.pick_random()
		var world_pos = map_to_local(random_map_pos)
		
		var tile_data = get_cell_tile_data(random_map_pos)
		var source_id = get_cell_source_id(random_map_pos)
		
		if source_id == 0 and not occupied_cells.has(random_map_pos):
			
			if random_map_pos == center_map_pos:
				continue

			if Global.world_changes.get(random_map_pos) == "removed":
				continue
			
			if tile_data and not tile_data.get_custom_data("water") and not occupied_cells.has(random_map_pos):
				var tree = DataManager.spawn_resource("oak_tree", world_pos)
				occupied_cells.append(random_map_pos)
				if tree and randf() > 0.5:
					var rand_size = randf_range(0.9, 1.25)
					tree.scale = Vector2(rand_size, rand_size)
					tree.scale.x *= -1
				spawned += 1

func spawn_starting_sinkhole():
	@warning_ignore("integer_division")
	var center_map_pos = Vector2i(world_width / 2, world_height / 2)
	
	var sinkhole_pos = center_map_pos + Vector2i(10, 10)

	object_layer.set_cell(sinkhole_pos, 1, Vector2i(0, 0))
	
	occupied_cells.append(sinkhole_pos)
