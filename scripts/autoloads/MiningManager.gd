extends Node

var tile_health_map = {}
var current_tilemap: TileMapLayer

func damage_block(world_pos: Vector2, tool_type, damage: int):
	if not current_tilemap: return
	
	var tile_pos = current_tilemap.local_to_map(current_tilemap.to_local(world_pos))
	var data = current_tilemap.get_cell_tile_data(tile_pos)
	
	if data:
		var block_id = data.get_custom_data("block_id")
		if not block_id:
			return
		
		var block_info = DataManager.get_resource(block_id)
		var preffered_tool_type = block_info.get("tool_type")
		var max_hp = block_info.get("hit_points", 1)
		
		if tool_type == preffered_tool_type:
			if not tile_health_map.has(tile_pos):
				tile_health_map[tile_pos] = max_hp
				
			tile_health_map[tile_pos] -= damage
				
			if tile_health_map[tile_pos] <= 0:
				destroy_block(tile_pos, block_info)

func destroy_block(tile_pos: Vector2, block_info: Dictionary):
	var fixed_pos = Vector2i(tile_pos)
	
	tile_health_map.erase(fixed_pos)
	current_tilemap.set_cells_terrain_connect([fixed_pos], 0, -1)
	
	var world_id = Global.current_world_id
	if not Global.world_changes.has(world_id):
		Global.world_changes[world_id] = {}
	
	Global.world_changes[world_id][fixed_pos] = "removed"

	var table_id = block_info.get("loot_ref")
	if table_id == "" or table_id == null:
		return
	
	var loot_items = DataManager.get_loot_table_items(table_id)
	for entry in loot_items:
		var roll = randf_range(0, 100)
		var chance = entry.get("weight", 0)
		
		if roll <= chance:
			var item_id = entry.get("item")
			var amount = randi_range(entry.get("amount_min"), entry.get("amount_max"))
			
			for i in range(amount):
				DataManager.spawn_item(item_id, current_tilemap.map_to_local(tile_pos), true)
