extends Node

var db_data = {}

func _ready():
	load_castle_db("res://data/Evergrent.json")

func load_castle_db(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var json_text = file.get_as_text()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	
	if error == OK:
		var full_data = json.data
		
		for sheet in full_data.sheets:
			if sheet.name == "Items":
				for row in sheet.lines:
					db_data[row.id] = row

func get_item(id):
	print("Hledám ID: ", id)
	print("Dostupná ID v databázi: ", db_data.keys())
	return db_data.get(id)
