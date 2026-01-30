extends Node

var world_seed: int = 0
var player_pos: Vector2 = Vector2.ZERO
var is_player_dead: bool = false
enum Difficulty {EASY, HARD}
var current_difficulty = Difficulty.EASY

var first_time_generation = true

var current_world_id : String = "surface"

var world_changes = {
	"surface": {},
	"underground": {}
}

var chunks = {}
var chunk_size = 10
var render_distance = 3

var world_scenes = {
	"surface": "res://scenes/main.tscn",
	"underground": "res://scenes/underground.tscn"
}

var current_layer = "surface"

func _ready():
	randomize()
	world_seed = randi()
	print("World seed is: ", world_seed)

func transition_to(target_layer: String):
	current_layer = target_layer
	get_tree().change_scene_to_file(world_scenes[target_layer])

func load_chunk(cx, cy, spawn_function: Callable, parent_node: Node2D):
	var chunk_pos = Vector2i(cx, cy)
	if chunks.has(chunk_pos): return
	
	chunks[chunk_pos] = null
	
	var chunk_node = Node2D.new()
	chunk_node.name = "Chunk_%d_%d" % [cx, cy]
	chunk_node.y_sort_enabled = true
	parent_node.add_child(chunk_node)
	chunks[chunk_pos] = chunk_node
	
	var count = 0
	for x in range(cx * chunk_size, (cx + 1) * chunk_size):
		for y in range(cy * chunk_size, (cy + 1) * chunk_size):
			spawn_function.call(x, y, chunk_node)
			
			count += 1
			if count % 15 == 0:
				await get_tree().process_frame

func unload_chunk(cx, cy):
	var chunks_to_remove = []
	
	var max_dist = render_distance + 1
	
	for chunk_pos in chunks.keys():
		if abs(chunk_pos.x - cx) > max_dist or abs(chunk_pos.y - cy) > max_dist:
			chunks_to_remove.append(chunk_pos)
			
	for c_pos in chunks_to_remove:
		var chunk_node = chunks[c_pos]
		if is_instance_valid(chunk_node):
			chunk_node.queue_free()
			
		chunks.erase(c_pos)

func get_player_world_position():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		return player.global_position
	return Vector2i.ZERO

func save_player_position():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player_pos = player.global_position
