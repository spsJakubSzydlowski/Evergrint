extends Node

const CURRENT_SAVE_VERSION = 1

var autosave_timer: Timer
const AUTOSAVE_TIMER_TIME = 30.0

var worlds_path: String

var world_changes = {
	"surface": {},
	"underground": {}
}

func _init() -> void:
	worlds_path = "user://Worlds"

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(worlds_path):
		DirAccess.make_dir_absolute(worlds_path)
		
	autosave_timer = Timer.new()
	autosave_timer.wait_time = AUTOSAVE_TIMER_TIME
	autosave_timer.autostart = true
	autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(autosave_timer)

func create_world(world_name: String, world_seed: int) -> bool:
	print("Creating world: ", world_name, "World seed: ", str(world_seed), ".")
	var success = true
	
	if not worlds_path.path_join(world_name + ".json"):
		success = false
		return success
	
	Global.time_created = Time.get_datetime_string_from_system()
	Global.last_played = Global.time_created
	Global.first_time_generation = true
	Global.world_name = world_name
	Global.world_seed = world_seed
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
	
	update_last_played(file_path)
	
	var data = _read_json_file(file_path)
	print("File path ", file_path)
	if data == null and FileAccess.file_exists(backup_path):
		print("Main save corrupted, trying backup...")
		data = _read_json_file(backup_path)
		used_backup = true
	
	if data == null:
		print_debug("ERROR: World JSON has not load currently")
		return success

	var save_version = data.get("version", 0)
	if save_version < CURRENT_SAVE_VERSION:
		data = migrate_save_data(data, save_version)
	
	var loaded_name = data.get("world_name", world_name)
	var loaded_seed = data.get("seed", 0)
	var loaded_last_played = data.get("last_played", null)
	var loaded_difficulty = data.get("difficulty", 0)
	var inventory = data.get("player_inventory", [])

	Global.world_name = loaded_name
	Global.world_seed = loaded_seed
	Global.last_played = loaded_last_played
	Global.current_difficulty = loaded_difficulty
	Inventory.slots = inventory
	Global.first_time_generation = false
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
	
	print("World: ", world_name, " (v", save_version, ") loaded successfully.")
	success = true
	return success

func delete_world(world_name: String):
	var normal_path = worlds_path + "/" + world_name + ".json"
	var bak_path = worlds_path + "/" + world_name + ".json.bak"
	
	if FileAccess.file_exists(normal_path):
		var error = DirAccess.remove_absolute(normal_path)
		if error == OK:
			print("World " + world_name + " Was successfully deleted!")
		else:
			printerr("Error occurred while deleting world: ", error)
	else:
		print("This world doesn't exist!")
		
	if FileAccess.file_exists(bak_path):
		var error = DirAccess.remove_absolute(bak_path)
		if error == OK:
			print("World backup " + world_name + " Was successfully deleted!")
		else:
			printerr("Error occurred while deleting backup: ", error)
	else:
		print("This world backup doesn't exist!")

func update_last_played(file_path):
	if not FileAccess.file_exists(file_path): return null
	
	var data = _read_json_file(file_path)
	
	if data == null: return null
	
	var current_time = Time.get_datetime_string_from_system()
	
	data["last_played"] = current_time
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()
		return data

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
				var full_file_path = worlds_path + "/" + world_full_name
				
				var world_data = _read_json_file(full_file_path)
				if world_data != null and typeof(world_data) == TYPE_DICTIONARY:
					var w_name = world_data["world_name"]
					var l_played = world_data["last_played"]
					var time_dict = Time.get_datetime_dict_from_datetime_string(l_played, false)
					
					var normal_l_played = "%d/%d/%d %02d:%02d:%02d" % [
						time_dict.day, 
						time_dict.month, 
						time_dict.year, 
						time_dict.hour, 
						time_dict.minute,
						time_dict.second
					]
					
					var world_info_dict = {
						"world_name": w_name,
						"last_played": normal_l_played
					}
					
					worlds.append(world_info_dict)
					
			world_full_name = worlds_folder.get_next()
		
		worlds.sort_custom(func(a, b): return a.get("last_played", 0) > b.get("last_played", 0))
		
		return worlds
	
	return worlds

func save_to_disk(world_name: String):
	if world_name == "" or world_name == null:
		return
	
	Global.last_played = Time.get_datetime_string_from_system()
	var file_path = worlds_path.path_join(world_name + ".json")
	var temp_path = file_path + ".tmp"
	var backup_path = file_path + ".bak"
	
	var data_to_save = {
			"version": CURRENT_SAVE_VERSION,
			"time_created": Global.time_created,
			"last_played": Global.last_played,
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
		file.store_string(JSON.stringify(data_to_save, "\t"))
		file.close()
		
		var dir = DirAccess.open(worlds_path)
		if dir.file_exists(world_name + ".json.bak"):
			dir.remove(backup_path)
			
		if dir.file_exists(world_name + ".json"):
			dir.rename(world_name + ".json", world_name + ".json.bak")
		
		dir.rename(world_name + ".json.tmp", world_name + ".json")
		
		print("World: ", world_name, " Saved. Backup created.")

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
