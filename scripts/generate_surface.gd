extends TileMapLayer

var noise = FastNoiseLite.new()
var river_noise = FastNoiseLite.new()
var world_width = 200
var world_height = 200

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.05
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	river_noise.seed = randi() + 1
	river_noise.frequency = 0.005
	river_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	generate_surface()
	
func generate_surface():
	for x in range(world_width):
		for y in range(world_height):
			var noise_val = noise.get_noise_2d(x, y)
			var river_val = river_noise.get_noise_2d(x, y)
			
			if abs(river_val) < 0.02:
				self.set_cell(Vector2i(x, y), 0, Vector2i(4, 1))
			elif abs(river_val) < 0.05:
				self.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			else:
				if noise_val > 0.2:
					self.set_cell(Vector2i(x, y), 0, Vector2i(4, 0))
				else:
					self.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
