extends TileMapLayer

var river_noise = FastNoiseLite.new()
var cave_noise = FastNoiseLite.new()
var world_width = 200
var world_height = 200

var center_map_pos

var occupied_cells = []

@export var object_layer: TileMapLayer

func _ready() -> void:
	while not DataManager.is_loaded:
		await get_tree().create_timer(0.1).timeout
	
	Signals.block_destroyed.connect(_on_block_destroyed)
	
	cave_noise.seed = Global.world_seed + 50
	cave_noise.frequency = 0.05
	
	river_noise.seed = Global.world_seed
	river_noise.frequency = 0.001
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_surface()
	var rect = get_used_rect()
	center_map_pos = rect.position + (rect.size / 2)
	
	spawn_starting_ladder()
	generate_blocks()
	
	
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
	var sinkhole_pos = center_map_pos

	object_layer.set_cell(sinkhole_pos, 2, Vector2i(0, 0))
	
	occupied_cells.append(sinkhole_pos)

func generate_blocks():
	print("START GENERATING BLOCKS")
	var stone_tiles : Array[Vector2i] = []
	
	var ladder_radius = 8.0
	var ladder_pos = center_map_pos
	
	for x in range(world_width):
		for y in range(world_height):
			var current_pos = Vector2i(x, y)
			
			var dist_from_ladder = Vector2(current_pos).distance_to(Vector2(ladder_pos))
			
			if dist_from_ladder < ladder_radius:
				continue
			
			var val = cave_noise.get_noise_2d(x, y)
			if val > -0.1:
				stone_tiles.append(Vector2i(x, y))
	
	if stone_tiles.size() > 0:
		object_layer.set_cells_terrain_connect(stone_tiles, 0, 4, false)

func _on_block_destroyed(global_pos):
	var map_pos = object_layer.local_to_map(global_pos)
	object_layer.set_cells_terrain_connect([map_pos], 0, -1)
	
	Global.world_changes[map_pos] = "removed"
