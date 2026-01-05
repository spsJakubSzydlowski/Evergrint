extends Node2D

@onready var player = null
@onready var tile_map: TileMapLayer = $TileMapLayer

@export var max_entities = 200

func _ready():
	if not DataManager.is_loaded:
		await DataManager.database_ready
	
	DataManager.spawn_player(Vector2(200, 100))
	
	player = get_tree().get_first_node_in_group("Player")

	DataManager.spawn_item("wooden_sword", Vector2(380, 100))
	DataManager.spawn_item("wooden_axe", Vector2(400, 100))
	DataManager.spawn_item("wooden_hammer", Vector2(420, 100))
	
func spawn_entity():
	var current_enemy_count = get_tree().get_nodes_in_group("entity").size()
	var spawn_pos = Vector2.ZERO
	var attempts = 0
	var found_valid_spot = false
	
	if current_enemy_count >= max_entities:
		return
	
	if player:
		while not found_valid_spot and attempts < 20:
			attempts += 1
			var random_angle = randf() * 2 * PI
			var distance = randf_range(get_viewport_rect().end.x, get_viewport_rect().end.x + 200)

			var offset = Vector2(cos(random_angle), sin(random_angle)) * distance

			spawn_pos = player.global_position + offset

			var map_pos = tile_map.local_to_map(spawn_pos)
			var tile_data = tile_map.get_cell_tile_data(map_pos)
			if tile_data and tile_data.get_custom_data("can_spawn"):
				found_valid_spot = true
		
		if found_valid_spot:
			DataManager.spawn_entity("green_slime", spawn_pos)


func _on_timer_timeout() -> void:
	spawn_entity()
