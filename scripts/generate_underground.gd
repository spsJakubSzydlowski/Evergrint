extends TileMapLayer

var river_noise = FastNoiseLite.new()
var world_width = 200
var world_height = 200

var center_map_pos

var occupied_cells = []

@export var object_layer: TileMapLayer

func _ready() -> void:
	while not DataManager.is_loaded:
		await get_tree().create_timer(0.1).timeout

	river_noise.seed = Global.world_seed
	river_noise.frequency = 0.001
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_surface()
	
	var rect = get_used_rect()
	center_map_pos = rect.position + (rect.size / 2)

	spawn_starting_sinkhole()
	
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

func spawn_starting_sinkhole():
	var sinkhole_pos = center_map_pos + Vector2i(10, 10)

	object_layer.set_cell(sinkhole_pos, 2, Vector2i(0, 0))
	
	occupied_cells.append(sinkhole_pos)
