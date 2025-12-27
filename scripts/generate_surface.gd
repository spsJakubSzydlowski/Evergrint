extends TileMapLayer

var noise = FastNoiseLite.new()
var river_noise = FastNoiseLite.new()
var world_width = 200
var world_height = 200

func _ready() -> void:
	river_noise.seed = randi() + 1
	river_noise.frequency = 0.001
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_surface()
	
func generate_surface():
	var grass_tiles : Array[Vector2i] = []
	var water_tiles : Array[Vector2i] = []
	var mountain_tiles : Array[Vector2i] = []
	
	for x in range(world_width):
		for y in range(world_height):
			#var noise_val = noise.get_noise_2d(x, y)
			var river_val = river_noise.get_noise_2d(x, y)
			
			if abs(river_val) < 0.01:
				water_tiles.append(Vector2i(x, y))
			elif abs(river_val) < 0.10:
				grass_tiles.append(Vector2i(x, y))
			else:
				#if noise_val > 0.2:
					#mountain_tiles.append(Vector2i(x, y))
				#else:
				grass_tiles.append(Vector2i(x, y))
					
	if grass_tiles.size() > 0:
		self.set_cells_terrain_connect(grass_tiles, 0, 0, false)
		#self.set_cells_terrain_connect(mountain_tiles, 0, 1, false)
		
	for pos in mountain_tiles:
		self.set_cell(pos, 0, Vector2i(4, 0))
		
	for pos in water_tiles:
		self.set_cell(pos, 0, Vector2i(0, 2))
		
