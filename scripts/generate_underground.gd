extends TileMapLayer

const T_STONE = 2
const T_LAVA = 3
const T_NOWALK = 5
const T_SAND = 6
const T_SNOW = 7
const T_BLOCK = 4

var moisture_noise = FastNoiseLite.new()
var temperature_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()
var world_width = Global.world_width
var world_height = Global.world_height

var sinkhole_map_pos

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

func _on_chunk_requested_rem(coords: Vector2i):
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	
	for x in range(start_x, start_x + Global.CHUNK_SIZE):
		for y in range(start_y, start_y + Global.CHUNK_SIZE):
			self.set_cell(Vector2i(x, y), -1)
			water_layer.set_cell(Vector2i(x, y), -1)
			object_layer.set_cell(Vector2i(x, y), -1)
	
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
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	temperature_noise.seed = Global.world_seed + 76576
	temperature_noise.frequency = 0.005
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	
	cave_noise.seed = Global.world_seed + 50
	cave_noise.frequency = 0.05
	cave_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	spawn_starting_sinkhole()
	notify_runtime_tile_data_update()

func get_biome_data(x: int, y: int) -> Dictionary:
	var mois = moisture_noise.get_noise_2d(x, y)
	var raw_temp = temperature_noise.get_noise_2d(x, y)
	
	var world_center = Global.center_world_pos
	var dist_to_center = Vector2(x, y).distance_to(world_center)
	
	var blend_factor = clamp(dist_to_center / 50.0, 0.0, 1.0)
	
	mois = lerp(0.0, mois, blend_factor)
	var blended_temp = lerp(0.0, raw_temp, blend_factor)
	
	var terrain_id = T_STONE
	
	if mois < -0.3:
		terrain_id = T_LAVA
	if blended_temp > 0.3:
		terrain_id = T_SAND
	elif blended_temp < -0.3:
		terrain_id = T_SNOW
	
	return {
		"terrain": terrain_id,
		"raw_temp": raw_temp
	}

func generate_chunk(coords):
	var water_tiles: Array[Vector2i] = []
	var block_tiles: Array[Vector2i] = []
	
	var rng = RandomNumberGenerator.new()
	rng.seed = Global.world_seed + coords.x * 17 + coords.y * 89
	
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	var end_x = start_x + Global.CHUNK_SIZE
	var end_y = start_y + Global.CHUNK_SIZE
	
	var changes = SaveManager.world_changes.get(Global.current_world_id, {})
	
	if start_x >= world_width or start_y >= world_height:
		return
		
	if start_x + Global.CHUNK_SIZE <= 0 or start_y + Global.CHUNK_SIZE <= 0:
		return
	
	var astar = get_parent().astar

	var sinkhole_radius_sq = sinkhole_radius * sinkhole_radius
	var time_start = Time.get_ticks_msec()
	
	for x in range(start_x - 1, end_x + 1):
		for y in range(start_y - 1, end_y + 1):
			var current_pos = Vector2i(x, y)
			
			var biome_data = get_biome_data(x, y)
			var terrain = biome_data.terrain
			
			var dx = x - sinkhole_map_pos.x
			var dy = y - sinkhole_map_pos.y
			var distance_sq = dx * dx + dy * dy
	
			if x >= start_x and x < end_x and y >= start_y and y < end_y:
				var base_terrain = terrain
				
				if base_terrain == T_LAVA:
					var temp = biome_data.raw_temp
					if temp > 0.3:
						base_terrain = T_SAND
					elif temp < -0.3:
						base_terrain = T_SNOW
					else:
						base_terrain = T_STONE
				
				if base_terrain == T_STONE:
					self.set_cell(current_pos, 0, Vector2i(rng.randi_range(0, 3), 3))
				elif base_terrain == T_SAND:
					self.set_cell(current_pos, 0, Vector2i(rng.randi_range(0, 3), 1))
				elif base_terrain == T_SNOW:
					self.set_cell(current_pos, 0, Vector2i(rng.randi_range(0, 3), 2))
			
			if terrain == T_LAVA:
				water_tiles.append(current_pos)
				astar.set_point_solid(current_pos, true)
			else:
				if distance_sq < sinkhole_radius_sq: continue
				if changes.has(current_pos):
					var change_type = changes[current_pos]

					if change_type == "removed":
						continue
						
				var val = cave_noise.get_noise_2d(x, y)
				if val > -0.1:
					block_tiles.append(current_pos)

				astar.set_point_solid(current_pos, true)
				
		if Time.get_ticks_msec() - time_start > 8:
			await get_tree().process_frame
			time_start = Time.get_ticks_msec()

	if water_tiles.size() > 0:
		await apply_terrain_in_batches(water_layer, water_tiles, T_LAVA)
	
	if block_tiles.size() > 0:
		await apply_terrain_in_batches(object_layer, block_tiles, T_BLOCK)

func apply_terrain_in_batches(layer, tiles, terrain_id, batch_size = 16) -> void:
	if tiles.is_empty():
		return
	
	for i in range(0, tiles.size(), batch_size):
		var batch = tiles.slice(i, i + batch_size)
		layer.set_cells_terrain_connect(batch, 0, terrain_id, true)
		await get_tree().process_frame

func spawn_starting_sinkhole():
	@warning_ignore("integer_division")
	var center_map_pos = Global.center_world_pos
	
	sinkhole_map_pos = center_map_pos

	object_layer.set_cell(sinkhole_map_pos, 2, Vector2i(0, 0))
	
	occupied_cells[sinkhole_map_pos] = true
