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

func save_game():
	print("Saving game...")
	var file_path = worlds_path.path_join("save_01.json")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	if file:
		var data_to_save = {
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
		
