extends Node

signal database_ready

var db_data = {}
var is_loaded = false

func _ready():
	load_castle_db("res://data/Evergrint.json")

func load_castle_db(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("ERROR: File was not found at:", path)
		return
	
	var json_text = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error == OK:
		var full_data = json.data
		
		for sheet in full_data.sheets:
			db_data[sheet.name] = {}
			
			for row in sheet.lines:
				if row.has("id"):
					db_data[sheet.name][row.id] = row
					
	is_loaded = true
	database_ready.emit()
			
func get_item(id):
	return db_data.get("Items", {}).get(id)

func get_loot_table(id):
	return db_data.get("LootTables", {}).get(id)

func get_loot_table_items(id):
	var table_row = get_loot_table(id)
	
	if table_row and table_row.has("items"):
		return table_row.items #Array
		
	return []

func get_melee_stats(id):
	return db_data.get("ActionStats", {}).get(id)

func _get_item_hit_box(id):
	var item = get_melee_stats(id)
	if item:
		return Vector2(item.get("hitbox_x", 1), item.get("hitbox_y", 1))
	return Vector2(1, 1)
	
func get_entity(id):
	return db_data.get("Entities", {}).get(id)

func get_resource(id):
	return db_data.get("Resources", {}).get(id)

func spawn_item(id: String, pos : Vector2, drop = false):
	if not is_loaded:
		await get_tree().create_timer(0.1).timeout
	
	(func():
		var item_scene = preload("res://scenes/world_object.tscn")
		var item_instance = item_scene.instantiate()
	
		get_tree().current_scene.add_child(item_instance)
	
		item_instance.position = pos
		if drop:
			var random_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			var jump_distance = randf_range(10.0, 30.0)
			var target_pos = pos + (random_direction * jump_distance)
			
			var tween = item_instance.create_tween().set_parallel(true)
			
			tween.tween_property(item_instance, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
			
			item_instance.scale = Vector2.ZERO
			tween.tween_property(item_instance, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
		item_instance.initialize(id)
	).call_deferred()
	

func spawn_entity(id: String, pos : Vector2):
	if not is_loaded:
		await get_tree().create_timer(0.1).timeout
		
	var entity_scene = preload("res://scenes/world_entity.tscn")
	var entity_instance = entity_scene.instantiate()
	
	get_tree().current_scene.add_child(entity_instance)
	entity_instance.position = pos
	
	entity_instance.initialize(id)

func spawn_resource(id: String, pos : Vector2):
	if not is_loaded:
		await get_tree().create_timer(0.1).timeout
		
	var resource_scene = preload("res://scenes/world_resource.tscn")
	var resource_instance = resource_scene.instantiate()
	
	get_tree().current_scene.add_child(resource_instance)
	resource_instance.position = pos
	
	resource_instance.initialize(id)
