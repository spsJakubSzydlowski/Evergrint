extends Node

var settings_path: String

var default_settings = {
	"sound_volume": 100
}

var current_settings = default_settings.duplicate()

func _init() -> void:
	if OS.has_feature("web"):
		settings_path = "user://settings.json"
	elif OS.has_feature("editor"):
		settings_path = "user://settings.json"
	else:
		settings_path = OS.get_executable_path().get_base_dir().path_join("settings.json")


func _ready() -> void:
	load_settings()

func save_settings():
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(current_settings, "\t"))
		file.close()
	else:
		printerr("Failed to save settings!")

func load_settings():
	if not FileAccess.file_exists(settings_path):
		print("Settings file not found, creating default.")
		await save_settings()
		apply_settings()
		return
		
	var file = FileAccess.open(settings_path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(content)
	
	if data == null or typeof(data) != TYPE_DICTIONARY:
		printerr("Settings file corrupted, loading defaults.")
		current_settings = default_settings.duplicate()
	else:
		current_settings = default_settings.duplicate()
		for key in data.keys():
			if current_settings.has(key):
				current_settings[key] = data[key]
				
	apply_settings()

func apply_settings():
	var master_bus = AudioServer.get_bus_index("Master")
	
	var raw_sound = current_settings.get("sound_volume", 100.0)
	var linear_volume = raw_sound / 100.0
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(linear_volume))

func update_setting(key: String, value):
	if current_settings.has(key):
		current_settings[key] = value
		apply_settings()
		save_settings()
