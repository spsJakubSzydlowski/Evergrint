extends Node

var tile_health_map = {}
var current_tilemap: TileMapLayer

func damage_block(world_pos: Vector2, _damage: int):
	if not current_tilemap: return
	
	var tile_pos = current_tilemap.local_to_map(current_tilemap.to_local(world_pos))
	var data = current_tilemap.get_cell_tile_data(tile_pos)
	
	if data:
		current_tilemap.set_cells_terrain_connect([tile_pos], 0, -1)
