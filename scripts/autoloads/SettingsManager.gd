extends Node

var settings_path: String

var default_audio_settings = {
	"sound_volume": 100
}

var current_audio_settings = default_audio_settings.duplicate()

func _init() -> void:
	settings_path = "user://settings.json"

func _ready() -> void:
	load_settings()

func save_settings():
	var save_data = {
		"audio": current_audio_settings,
		"controls": Controls.controls
	}
	
	var file = FileAccess.open(settings_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
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
		reset_to_defaults()
	else:
		if data.has("audio") and typeof(data["audio"]) == TYPE_DICTIONARY:
			for key in data["audio"]:
				current_audio_settings[key] = data["audio"][key]
		
		if data.has("controls") and typeof(data["controls"]) == TYPE_DICTIONARY:
			for key in data["controls"]:
				Controls.controls[key] = data["controls"][key]
				
	apply_settings()

func reset_to_defaults():
	current_audio_settings = default_audio_settings.duplicate()
	Controls.controls = Controls.default_controls.duplicate()
	
func apply_settings():
	var master_bus = AudioServer.get_bus_index("Master")
	
	var raw_sound = current_audio_settings.get("sound_volume", 100.0)
	var linear_volume = raw_sound / 100.0
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(linear_volume))

func update_setting(key: String, value):
	if current_audio_settings.has(key):
		current_audio_settings[key] = value
		apply_settings()
	if Controls.controls.has(key):
		Controls.controls[key] = value
