extends Node

var worlds_path: String

var world_changes = {
	"surface": {},
	"underground": {}
}

func _init() -> void:
	if OS.has_feature("editor"):
		worlds_path = ProjectSettings.globalize_path("res://Worlds")
	else:
		worlds_path = OS.get_executable_path().get_base_dir().path_join("Worlds")

func _ready() -> void:
	if not DirAccess.dir_exists_absolute(worlds_path):
		DirAccess.make_dir_absolute(worlds_path)

func create_world(world_name: String) -> bool:
	var success = true
	
	if not worlds_path.path_join(world_name + ".json"):
		success = false
		return success
	
	print("Creating new world...")
	Global.world_seed = randi()
	world_changes = {"surface": {}, "underground": {}}
	
	save_to_disk(world_name)
	return success

func save_world(world_name: String):
	print("Saving world: " + world_name)
	
	save_to_disk(world_name)

func load_world(world_name: String) -> bool:
	var success = false
	print("Loading world: " + world_name)
	var file_path = worlds_path.path_join(world_name + ".json")
	if not FileAccess.file_exists(file_path):
		return success
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	if data:
		var loaded_seed = data["seed"]
		var loaded_difficulty = data["difficulty"]
		var inventory = data["player_inventory"]
		var first_time_generation = data["first_time"]
		
		Global.world_seed = loaded_seed
		Global.current_difficulty = loaded_difficulty
		Inventory.slots = str_to_var(inventory)
		Global.first_time_generation = first_time_generation
		
		world_changes = {"surface": {}, "underground": {}}
		var changes = data["changes"]
		
		for layer in ["surface", "underground"]:
			for pos_string in changes[layer].keys():
				var pos = str_to_var(pos_string)
				world_changes[layer][pos] = changes[layer][pos_string]
		
		print("Game loaded from file: ", file_path)
		print("World seed: " + str(Global.world_seed))
		print("World name: " + world_name)
		print("World difficulty " + str(Global.current_difficulty))
		success = true
		return success
	return success

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
	var file_path = worlds_path.path_join(world_name + ".json")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		var data_to_save = {
				"first_time": Global.first_time_generation,
				"player_inventory": var_to_str(Inventory.slots),
				"seed": Global.world_seed,
				"difficulty": Global.current_difficulty,
				"changes": {
						"surface": {},
						"underground": {}
				}
		}
		
		for layer in world_changes.keys():
			for pos in world_changes[layer].keys():
				var pos_string = pos
				data_to_save["changes"][layer][pos_string] = world_changes[layer][pos]
				
		file.store_string(JSON.stringify(data_to_save, "\t"))
		file.close()
		print("Game saved in file: ", file_path)
		print("World seed: " + str(Global.world_seed))
		print("World name: " + world_name)
		print("World difficulty: " + str(Global.current_difficulty))
