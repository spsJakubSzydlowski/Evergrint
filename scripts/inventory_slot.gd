extends PanelContainer

signal slot_clicked(slot_ui)

var slot_index = -1

@onready var icon: TextureRect = $Contents/Icon

func _ready() -> void:
	if has_meta("equipment_type"):
		var slot_type = get_meta("equipment_type")
		var path = "res://textures/atlas_resources/ui_" + str(slot_type) + ".tres"
		
		if ResourceLoader.exists(path):
			icon.texture = load(path)
		else:
			printerr("Atlas resource doesn't exist: " + path)

func _gui_input(event: InputEvent) -> void:
	if Global.is_player_dead or Global.world_name == "":
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			slot_clicked.emit(self)

func update_to_default_icon(slot_type: String):
	var path = "res://textures/atlas_resources/ui_" + str(slot_type) + ".tres"
	
	if ResourceLoader.exists(path):
		icon.texture = load(path)
	else:
		printerr("Atlas resource doesn't exist: " + path)
