extends Node2D

# Pomocí @onready získáme odkaz na Sprite hned po načtení
@onready var sprite = $Sprite2D

func initialize(item_id: String):
	# 1. Vytáhneme data z DataManageru
	var data = DataManager.db_data.get(item_id)
	
	if data == null:
		print("Chyba: ID ", item_id, " v databázi neexistuje!")
		return

	# 2. Zapneme Region na Spritu (to nám dovolí výřez z atlasu)
	sprite.region_enabled = true
	
	# 3. CastleDB ukládá informace o Tile obvykle takto:
	# item.icon.x a item.icon.y (indexy dlaždic)
	# Pokud tam máš indexy (0, 1, 2...), musíme je vynásobit velikostí (16)
	var tile_size = 16
	var rect_x = data.icon.x * tile_size
	var rect_y = data.icon.y * tile_size
	
	# Pokud tvůj objekt zabírá víc dlaždic (třeba strom 3x5), 
	# CastleDB to má v polích 'width' a 'height' (v počtu dlaždic)
	var rect_w = data.icon.width * tile_size
	var rect_h = data.icon.height * tile_size
	
	# 4. Nastavíme výřez spritu
	sprite.region_rect = Rect2(rect_x, rect_y, rect_w, rect_h)
