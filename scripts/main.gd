extends Node2D

var player = null
@onready var tile_map: TileMapLayer = $TileMapLayer

@export var max_entities = 200


func _ready():
	if not DataManager.is_loaded:
		await DataManager.database_ready
	
	if Global.first_time_generation:
		
		spawn_player_at_center()
		player = get_tree().get_first_node_in_group("Player")
		
		DataManager.spawn_item("wooden_sword", player.global_position, false)
		DataManager.spawn_item("wooden_axe", player.global_position, false)
		DataManager.spawn_item("wooden_hammer", player.global_position, false)
		DataManager.spawn_item("wooden_bow", player.global_position, false)
		for i in range(10):
			DataManager.spawn_item("arrow", player.global_position, false)
		
		Global.first_time_generation = false
	else:
		var return_pos = Global.player_pos
		DataManager.spawn_player(return_pos)

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

func spawn_player_at_center():
	var rect = tile_map.get_used_rect()
	var center_map_pos = rect.position + (rect.size / 2)
	
	var center_world_pos = tile_map.map_to_local(center_map_pos)
	
	DataManager.spawn_player(center_world_pos)

func _on_timer_timeout() -> void:
	spawn_entity()
