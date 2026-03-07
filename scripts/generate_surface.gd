extends TileMapLayer

const T_GRASS = 0
const T_WATER = 1
const T_NOWALK = 5

var moisture_noise = FastNoiseLite.new()
var temperature_noise = FastNoiseLite.new()
var world_width = Global.world_width
var world_height = Global.world_height
var tree_count = 800

var sinkhole_radius = 8.0

var occupied_cells = {}
var loaded_chunks_entities : Dictionary = {}


@export var object_layer: TileMapLayer
@export var water_layer: TileMapLayer

func _ready() -> void:
	Global.request_chunk_generation.connect(_on_chunk_requested_gen)
	Global.request_chunk_removal.connect(_on_chunk_requested_rem)

func _on_chunk_requested_gen(coords: Vector2i):
	generate_chunk(coords)
	spawn_trees_in_chunk(coords)
	
func _on_chunk_requested_rem(coords: Vector2i):
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	
	for x in range(start_x, start_x + Global.CHUNK_SIZE):
		for y in range(start_y, start_y + Global.CHUNK_SIZE):
			self.set_cell(Vector2i(x, y), -1)
			water_layer.set_cell(Vector2i(x, y), -1)
	
	if loaded_chunks_entities.has(coords):
		var resources_to_delete = loaded_chunks_entities[coords]
	
		for data in resources_to_delete:
			if is_instance_valid(data.node):
				data.node.queue_free()
			occupied_cells.erase(data.cell_pos)
				
		loaded_chunks_entities.erase(coords)

func generate() -> void:
	occupied_cells.clear()
	moisture_noise.seed = Global.world_seed
	moisture_noise.frequency = 0.01
	moisture_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	temperature_noise.seed = Global.world_seed + 76576
	temperature_noise.frequency = 0.005

	spawn_starting_sinkhole()
	notify_runtime_tile_data_update()

func get_biome_terrain(x: int, y: int) -> int:
	var mois = moisture_noise.get_noise_2d(x, y)
	#var temp = temperature_noise.get_noise_2d(x, y)
	
	if mois < -0.3:
		return T_WATER
	
	return T_GRASS

func generate_chunk(coords):
	var water_tiles: Array[Vector2i] = []
	
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	var end_x = start_x + Global.CHUNK_SIZE
	var end_y = start_y + Global.CHUNK_SIZE
	
	if start_x >= world_width or start_y >= world_height:
		return
		
	if start_x + Global.CHUNK_SIZE <= 0 or start_y + Global.CHUNK_SIZE <= 0:
		return
	
	for x in range(start_x - 1, end_x + 1):
		for y in range(start_y - 1, end_y + 1):
			var current_pos = Vector2i(x, y)
			var terrain = get_biome_terrain(x, y)

			if x >= start_x and x < end_x and y >= start_y and y < end_y:
				var base_terrain = terrain
				
				if base_terrain == T_WATER:
					base_terrain = T_NOWALK
				
				if base_terrain == T_GRASS:
					self.set_cell(current_pos, 0, Vector2i(randi_range(4, 7), 1))
			
				if base_terrain == T_NOWALK:
					self.set_cell(current_pos, 0, Vector2i(8, 1))
				
			if terrain == T_WATER:
				water_tiles.append(current_pos)

	if water_tiles.size() > 0:
		water_layer.set_cells_terrain_connect(water_tiles, 0, T_WATER, true)

func spawn_trees_in_chunk(coords):
	var rng = RandomNumberGenerator.new()
	rng.seed = Global.world_seed + coords.x * 37 + coords.y * 131
	
	if not loaded_chunks_entities.has(coords):
		loaded_chunks_entities[coords] = []
	
	var sinkhole_map_pos = Global.center_world_pos
	
	var tree_density = rng.randi() % 3
	
	for i in range(tree_density):
		var local_pos = Vector2i(rng.randi() % Global.CHUNK_SIZE, rng.randi() % Global.CHUNK_SIZE)
		var global_tile_pos = Vector2i((coords * Global.CHUNK_SIZE) + local_pos)
		
		var dist_from_sinkhole = Vector2(global_tile_pos).distance_to(Vector2(sinkhole_map_pos))
		
		var changes = SaveManager.world_changes.get(Global.current_world_id, {})

		if global_tile_pos.x >= Global.world_width or global_tile_pos.y >= Global.world_height: continue
		if occupied_cells.has(global_tile_pos): continue
		if dist_from_sinkhole < sinkhole_radius: continue

		var water_tile_data = water_layer.get_cell_tile_data(global_tile_pos)
		if water_tile_data and water_tile_data.get_custom_data("water"): continue
		
		var world_pos = MiningManager.current_tilemap.map_to_local(global_tile_pos)

		if changes.has(global_tile_pos):
			var change_type = changes[global_tile_pos]

			if change_type == "removed":
				continue
			elif change_type == "placed":
				pass
		
		var tree = DataManager.spawn_resource("oak_tree", world_pos)
		
		if tree:
			occupied_cells[global_tile_pos] = true
			
			loaded_chunks_entities[coords].append({
				"node": tree,
				"cell_pos": global_tile_pos
			})

			var rand_size = rng.randf_range(0.95, 1.2)
			tree.scale = Vector2(rand_size, rand_size)
			if rng.randi_range(1, 2) == 1:
				tree.scale.x *= -1 

func spawn_starting_sinkhole():
	@warning_ignore("integer_division")
	var center_map_pos = Global.center_world_pos
	
	var sinkhole_pos = center_map_pos

	object_layer.set_cell(sinkhole_pos, 1, Vector2i(0, 0))
	
	occupied_cells[sinkhole_pos] = true
