extends TileMapLayer

const GRASS_TERRAIN = 0
const WATER_TERRAIN = 2

var river_noise = FastNoiseLite.new()
var world_width = Global.world_width
var world_height = Global.world_height
var tree_count = 800

var occupied_cells = {}

@export var object_layer: TileMapLayer

func _ready() -> void:
	Global.request_chunk_generation.connect(_on_chunk_requested)

func _on_chunk_requested(coords: Vector2i):
	print("Request chunks in surface: " + str(coords))
	generate_chunk(coords)
	spawn_trees_in_chunk(coords)

func generate() -> void:
	occupied_cells.clear()
	river_noise.seed = Global.world_seed
	river_noise.frequency = 0.01
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	spawn_starting_sinkhole()
	notify_runtime_tile_data_update()

func generate_chunk(coords):
	print("Generating chunk...")

	var grass_tiles : Array[Vector2i] = []
	var water_tiles : Array[Vector2i] = []
	
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	var end_x = start_x + Global.CHUNK_SIZE
	var end_y = start_y + Global.CHUNK_SIZE
	
	for x in range(start_x, end_x):
		if x < 0 or x >= world_width: 
			continue
		
		for y in range(start_y, end_y):
			if y < 0 or y >= world_height:
				continue

			var current_pos = Vector2i(x, y)

			var val = river_noise.get_noise_2d(x, y)
			if val < -0.2:
				water_tiles.append(current_pos)
			else:
				grass_tiles.append(current_pos)
		
	if grass_tiles.size() > 0:
		self.set_cells_terrain_connect(grass_tiles, 0, GRASS_TERRAIN, false)
		
	if water_tiles.size() > 0:
		self.set_cells_terrain_connect(water_tiles, 0, WATER_TERRAIN, false)

func spawn_trees_in_chunk(coords):
	seed(Global.world_seed + coords.x * 37 + coords.y * 131)

	var tree_density = randi() % 3
	
	for i in range(tree_density):
		var local_pos = Vector2i(randi() % Global.CHUNK_SIZE, randi() % Global.CHUNK_SIZE)
		var global_tile_pos = (coords * Global.CHUNK_SIZE) + local_pos
		
		if global_tile_pos.x >= Global.world_width or global_tile_pos.y >= Global.world_height: continue
		
		var tile_data = self.get_cell_tile_data(global_tile_pos)
		if tile_data and tile_data.get_custom_data("water"): continue
		
		var world_pos = self.map_to_local(global_tile_pos)
		var tree = DataManager.spawn_resource("oak_tree", world_pos)
		
		if tree:
			occupied_cells[global_tile_pos] = true 

			var rand_size = randf_range(0.9, 1.25)
			tree.scale = Vector2(rand_size, rand_size)
			tree.scale.x *= -1 

func spawn_starting_sinkhole():
	@warning_ignore("integer_division")
	var center_map_pos = Vector2i(world_width / 2, world_height / 2)
	
	var sinkhole_pos = center_map_pos

	object_layer.set_cell(sinkhole_pos, 1, Vector2i(0, 0))
	
	occupied_cells[sinkhole_pos] = true
