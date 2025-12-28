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

func get_melee_stats(id):
	return db_data.get("MeleeStats", {}).get(id)

func _get_item_hit_box(id):
	var item = get_melee_stats(id)
	if item:
		return Vector2(item.get("hitbox_x", 1), item.get("hitbox_y", 1))
	return Vector2(1, 1)
	
func get_entity(id):
	return db_data.get("Entities", {}).get(id)

func spawn_item(id: String, pos : Vector2):
	if not is_loaded:
		await get_tree().create_timer(0.1).timeout
		
	var item_scene = preload("res://scenes/world_object.tscn")
	var item_instance = item_scene.instantiate()
	
	get_tree().current_scene.add_child(item_instance)
	
	item_instance.position = pos
	item_instance.initialize(id)

func spawn_entity(id: String, pos : Vector2):
	if not is_loaded:
		await get_tree().create_timer(0.1).timeout
		
	var entity_scene = preload("res://scenes/world_entity.tscn")
	var entity_instance = entity_scene.instantiate()
	
	get_tree().current_scene.add_child(entity_instance)
	entity_instance.position = pos
	
	entity_instance.initialize(id)
