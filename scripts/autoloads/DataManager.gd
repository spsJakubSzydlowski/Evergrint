extends Node

signal database_ready

var db_data = {}
var is_loaded = false

var weapon_stats_map = {}

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
		
		if full_data.has("sheets"):
			for sheet in full_data["sheets"]:
				var sheet_name = sheet["name"]
				db_data[sheet_name] = {}
				
				for row in sheet["lines"]:
					if row.has("id"):
						db_data[sheet.name][row["id"]] = row
					elif row.has("item_ref"):
						db_data[sheet.name][row["item_ref"]] = row
					
		is_loaded = true
		database_ready.emit()
		
		#print("Database loaded successfully. Sheets found: ", db_data.keys())
	else:
		print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
			
func get_item(id):
	return db_data.get("Items", {}).get(id)

func get_weapon_stats(id):
	if db_data.has("ActionStats") and db_data["ActionStats"].has(id):
		return db_data["ActionStats"][id]
	return {}

func get_projectile_stats(id):
	if db_data.has("ProjectileStats") and db_data["ProjectileStats"].has(id):
		return db_data["ProjectileStats"][id]
	return {}

func get_loot_table(id):
	return db_data.get("LootTables", {}).get(id)

func get_loot_table_items(id):
	var table_row = get_loot_table(id)
	
	if table_row and table_row.has("items"):
		return table_row.items #Array
		
	return []

func get_entity(id):
	return db_data.get("Entities", {}).get(id)

func get_full_entity_data(id):
	var base_data = get_entity(id)
	if not base_data:
		return {}
	
	var final_data = base_data.duplicate()
	
	var p_stats = db_data.get("PlayerStats", {}).get(id)
	if p_stats:
		for key in p_stats:
			final_data[key] = p_stats[key]
			
	var e_stats = db_data.get("EnemyStats", {}).get(id)
	if e_stats:
		for key in e_stats:
			final_data[key] = e_stats[key]
			
	return final_data

func get_resource(id):
	return db_data.get("Resources", {}).get(id)

func spawn_item(id: String, pos : Vector2, drop = true):
	if not is_loaded:
		await get_tree().create_timer(0.1).timeout
	
	(func():
		var item_scene = preload("res://scenes/world_object.tscn")
		var item_instance = item_scene.instantiate()
	
		get_tree().current_scene.add_child(item_instance)
		item_instance.global_position = pos
		
		if drop:
			var random_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
			var jump_distance = randf_range(10.0, 30.0)
			var target_pos = pos + (random_direction * jump_distance)
			
			var tween = get_tree().create_tween().set_parallel(true)
			tween.bind_node(item_instance)
			
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

func spawn_player(pos : Vector2):
	if not is_loaded:
		await get_tree().create_timer(0.1).timeout
		
	var player_scene = preload("res://scenes/player.tscn")
	var player_instance = player_scene.instantiate()
	
	get_tree().current_scene.add_child(player_instance)
	player_instance.position = pos
	
	player_instance.initialize()

func spawn_resource(id: String, pos : Vector2):
	var resource_scene = preload("res://scenes/world_resource.tscn")
	var resource_instance = resource_scene.instantiate()
	
	get_tree().current_scene.add_child.call_deferred(resource_instance)
	resource_instance.position = pos
	
	resource_instance.initialize(id)
	
	return resource_instance
