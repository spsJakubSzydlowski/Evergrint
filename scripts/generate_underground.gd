extends TileMapLayer

var river_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()
var world_width = Global.world_width
var world_height = Global.world_height
var ladder_radius = 8.0

var occupied_cells = {}

@export var object_layer: TileMapLayer

func _ready() -> void:
	Global.request_chunk_generation.connect(_on_chunk_requested_gen)
	Global.request_chunk_removal.connect(_on_chunk_requested_rem)

func generate() -> void:
	occupied_cells.clear()
	cave_noise.seed = Global.world_seed + 50
	cave_noise.frequency = 0.05
	
	river_noise.seed = Global.world_seed
	river_noise.frequency = 0.02
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN

	spawn_starting_ladder()

	notify_runtime_tile_data_update()

func spawn_starting_ladder():
	var sinkhole_pos = Global.center_world_pos

	object_layer.set_cell(sinkhole_pos, 2, Vector2i(0, 0))
	
	occupied_cells[sinkhole_pos] = true

func _on_chunk_requested_gen(coords: Vector2i):
	generate_surface(coords)
	generate_chunk(coords)

func _on_chunk_requested_rem(coords: Vector2i):
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	var center_map_pos = Global.center_world_pos

	for x in range(start_x, start_x + Global.CHUNK_SIZE):
		for y in range(start_y, start_y + Global.CHUNK_SIZE):
			var current_pos = Vector2i(x, y)
			
			if current_pos == center_map_pos:
				continue
				
			self.set_cell(current_pos, -1)
			object_layer.set_cell(current_pos, -1)
	
func generate_surface(coords):
	var stone_tiles : Array[Vector2i] = []
	var lava_tiles : Array[Vector2i] = []
	
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	var end_x = start_x + Global.CHUNK_SIZE
	var end_y = start_y + Global.CHUNK_SIZE
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):

			var val = river_noise.get_noise_2d(x, y)
			if val < -0.2:
				lava_tiles.append(Vector2i(x ,y))
			else:
				stone_tiles.append(Vector2i(x ,y))
		
	if stone_tiles.size() > 0:
		self.set_cells_terrain_connect(stone_tiles, 0, 1, false)
		
	if lava_tiles.size() > 0:
		self.set_cells_terrain_connect(lava_tiles, 0, 3, false)

func generate_chunk(coords):
	var stone_tiles : Array[Vector2i] = []
	
	var ladder_map_pos = Global.center_world_pos
	
	var changes = SaveManager.world_changes.get(Global.current_world_id, {})
	
	var start_x = coords.x * Global.CHUNK_SIZE
	var start_y = coords.y * Global.CHUNK_SIZE
	var end_x = start_x + Global.CHUNK_SIZE
	var end_y = start_y + Global.CHUNK_SIZE
	
	for x in range(start_x, end_x):
		for y in range(start_y, end_y):
			var current_pos = Vector2i(x, y)
			
			var dist_from_ladder = Vector2(current_pos).distance_to(Vector2(ladder_map_pos))

			var tile_data = get_cell_tile_data(current_pos)
			if tile_data and tile_data.get_custom_data("water"):
				continue

			if dist_from_ladder < ladder_radius:
				continue
			
			if current_pos == ladder_map_pos:
				spawn_starting_ladder()
			
			if changes.has(current_pos):
				var change_type = changes[current_pos]

				if change_type == "removed":
					continue
				elif change_type == "placed":
					pass
			
			if x % 5 == 0:
				await get_tree().process_frame

			var val = cave_noise.get_noise_2d(x, y)
			if val > -0.1:
				stone_tiles.append(Vector2i(x, y))

	if stone_tiles.size() > 0:
		object_layer.set_cells_terrain_connect(stone_tiles, 0, 4, false)
