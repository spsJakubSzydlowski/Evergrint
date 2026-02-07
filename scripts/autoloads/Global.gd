extends Node

signal request_chunk_generation(coords: Vector2i)
signal request_chunk_removal(coords: Vector2i)

var world_seed: int = 0
var player_pos: Vector2 = Vector2.ZERO
var is_player_dead: bool = false
enum Difficulty {EASY, HARD}
var current_difficulty = Difficulty.EASY
var difficulty_multiplier: float = 1.0

var living_boss: bool = false

var world_width: int = 1000
var world_height: int = 1000
@warning_ignore("integer_division")
var center_world_pos = Vector2i(world_width / 2, world_height / 2)

var first_time_generation: bool = true

var world_changes = {
	"surface": {},
	"underground": {}
}

var loaded_chunks = {}
var chunk_queue: Array[Vector2i] = []
const CHUNK_SIZE = 8
const RENDER_DISTANCE = 4

var world_scenes = {
	"surface": "res://scenes/main.tscn",
	"underground": "res://scenes/underground.tscn"
}
var current_world_id : String = "surface"

func _ready():
	randomize()
	world_seed = randi()
	print("World seed is: ", world_seed)

func set_difficulty(mode: String):
	if mode == "hard":
		difficulty_multiplier = 1.5
	else:
		difficulty_multiplier = 1.0

func transition_to(target_layer: String):
	SceneChanger.change_scene(world_scenes[target_layer])
	current_world_id = target_layer
	loaded_chunks.clear()

func get_player_world_position():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player.global_position
	return center_world_pos

func save_player_position():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player_pos = player.global_position

func update_chunks(tile_map):
	var player_chunk_pos = get_player_chunk_pos(tile_map)

	var chunks_to_see = []
	var chunks_to_unload = []
	
	var max_chunk_x = ceil(world_width / float(CHUNK_SIZE))
	var max_chunk_y = ceil(world_height / float(CHUNK_SIZE))
	
	for x in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
		for y in range(-RENDER_DISTANCE, RENDER_DISTANCE + 1):
			var chunk_coords = player_chunk_pos + Vector2i(x, y)
			chunks_to_see.append(chunk_coords)
			
			if chunk_coords.x >= 0 and chunk_coords.x < max_chunk_x:
				if chunk_coords.y >= 0 and chunk_coords.y < max_chunk_y:
					
					if not loaded_chunks.has(chunk_coords):
						if not chunk_coords in chunk_queue:
							chunk_queue.append(chunk_coords)
	
	var UNLOAD_DISTANCE = RENDER_DISTANCE + 2
	for loaded_coords in loaded_chunks.keys():
		var dist_x = abs(loaded_coords.x - player_chunk_pos.x)
		var dist_y = abs(loaded_coords.y - player_chunk_pos.y)
		
		if dist_x > UNLOAD_DISTANCE or dist_y > UNLOAD_DISTANCE:
			chunks_to_unload.append(loaded_coords)

	for coords in chunks_to_unload:
		request_chunk_removal.emit(coords)
		loaded_chunks.erase(coords)

func _process(_delta):
	if chunk_queue.size() > 0:
		var next_chunk = chunk_queue.pop_front()
		loaded_chunks[next_chunk] = true
		request_chunk_generation.emit(next_chunk)

func get_player_chunk_pos(tile_map):
	var player_global_pos = get_player_world_position()
	
	var player_tile_pos = tile_map.local_to_map(player_global_pos)
	var player_chunk_pos = Vector2i(
		floor(player_tile_pos.x / float(CHUNK_SIZE)),
		floor(player_tile_pos.y / float(CHUNK_SIZE))
	)
	return player_chunk_pos
