extends Node

const CURRENT_SAVE_VERSION = 1

var autosave_timer: Timer

var worlds_path: String

var world_changes = {
	"surface": {},
	"underground": {}
}

func _init() -> void:
	if OS.has_feature("web"):
		worlds_path = "user://Worlds"
	elif OS.has_feature("editor"):
		worlds_path = "user://Worlds"
	else:
		worlds_path = OS.get_executable_path().get_base_dir().path_join("Worlds")

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(worlds_path):
		DirAccess.make_dir_absolute(worlds_path)
		
	autosave_timer = Timer.new()
	autosave_timer.wait_time = 10.0
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(autosave_timer)

func create_world(world_name: String) -> bool:
	var success = true
	
	if not worlds_path.path_join(world_name + ".json"):
		success = false
		return success
	
	print("Creating new world: ", world_name)
	Global.world_seed = randi()
	Global.world_name = world_name
	world_changes = {"surface": {}, "underground": {}}
	
	save_to_disk(world_name)
	return success

func load_world(world_name: String) -> bool:
	var success = false
	if world_name == "" or world_name == null:
		return success
	
	var file_path = worlds_path.path_join(world_name + ".json")
	var backup_path = file_path + ".bak"
	var used_backup = false
	
	var data = _read_json_file(file_path)
	if data == null and FileAccess.file_exists(backup_path):
		print("Main save corrupted, trying backup...")
		data = _read_json_file(backup_path)
		used_backup = true
	
	if data == null:
		return success

	var save_version = data.get("version", 0)
	if save_version < CURRENT_SAVE_VERSION:
		data = migrate_save_data(data, save_version)
	
	var loaded_name = data.get("world_name", world_name)
	var loaded_seed = data.get("seed", 0)
	var loaded_difficulty = data.get("difficulty", 0)
	var inventory = data.get("player_inventory", [])
	var first_time_generation = data.get("first_time", true)
	
	Global.world_name = loaded_name
	Global.world_seed = loaded_seed
	Global.current_difficulty = loaded_difficulty
	Inventory.slots = inventory
	Global.first_time_generation = first_time_generation
	Global.world_name = world_name
	
	world_changes = {"surface": {}, "underground": {}}
	var changes = data["changes"]
	
	for layer in ["surface", "underground"]:
		if not changes.has(layer): continue
		for pos_string in changes[layer].keys():
			var pos_vector = str_to_var(pos_string)
			world_changes[layer][pos_vector] = changes[layer][pos_string]
	
	if used_backup:
		print("Restoring main save from backup...")
		save_to_disk(world_name)
	
	print("World ", world_name, " (v", save_version, ") loaded successfully.")
	success = true
	return success

func _read_json_file(path: String):
	if not FileAccess.file_exists(path): return null
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return JSON.parse_string(content)

func get_all_worlds():
	var worlds_folder = DirAccess.open(worlds_path)
	var worlds = []
	
	if worlds_folder:
		worlds_folder.list_dir_begin()
		var world_full_name = worlds_folder.get_next()
		
		while world_full_name != "":
			if world_full_name.get_extension() == "json":
				var world_name = world_full_name.get_basename()
				worlds.append(world_name)
			world_full_name = worlds_folder.get_next()
			
		return worlds
	
	return worlds

func save_to_disk(world_name: String):
	if world_name == "" or world_name == null:
		return
	
	var file_path = worlds_path.path_join(world_name + ".json")
	var temp_path = file_path + ".tmp"
	var backup_path = file_path + ".bak"
	
	var data_to_save = {
			"version": CURRENT_SAVE_VERSION,
			"world_name": Global.world_name,
			"first_time": Global.first_time_generation,
			"player_inventory": Inventory.slots,
			"seed": Global.world_seed,
			"difficulty": Global.current_difficulty,
			"changes": {
					"surface": {},
					"underground": {}
			}
	}
	
	for layer in world_changes.keys():
		for pos in world_changes[layer].keys():
			var actual_pos = pos
			if typeof(pos) == TYPE_STRING:
				actual_pos = str_to_var(pos.replace('"', ''))
			
			var pos_string = var_to_str(actual_pos)
			data_to_save["changes"][layer][pos_string] = world_changes[layer][pos]
	
	var file = FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data_to_save))
		file.close()
		
		var dir = DirAccess.open(worlds_path)
		if dir.file_exists(world_name + ".json.bak"):
			dir.remove(backup_path)
			
		if dir.file_exists(world_name + ".json"):
			dir.rename(world_name + ".json", world_name + ".json.bak")
		
		dir.rename(world_name + ".json.tmp", world_name + ".json")
		
		print("World Saved, backup created")

func migrate_save_data(data, old_version):
	print("Migrating save from v", old_version, " to v", CURRENT_SAVE_VERSION)
	
	if old_version < 1:
		pass
		
	data["version"] = CURRENT_SAVE_VERSION
	return data

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Global.world_name != "":
			save_to_disk(Global.world_name)
		get_tree().quit()

func _on_autosave_timeout():
	if Global.world_name != "":
		print("Autosaving... World name: " + Global.world_name)
		save_to_disk(Global.world_name)
