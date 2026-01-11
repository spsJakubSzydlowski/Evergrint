extends CanvasLayer

signal item_equipped(item_id)

@onready var hotbar_container: HBoxContainer = $hotbar
@onready var health_bar: TextureProgressBar = $health_bar
@onready var inventory_container: GridContainer = $inventory

var first_selected_slot_index = -1

var slot_scene = preload("res://scenes/UI/inventory_slot.tscn")
var active_slot_index = 0

var hotbar_slots = 10
var inventory_slots = 50

var is_inventory_open = false

func _ready() -> void:
	Signals.player_health_changed.connect(update_health_bar)
	
	Inventory.inventory_updated.connect(on_inventory_updated)
	refresh_ui()
	emit_equipped_signal()
	
func on_inventory_updated():
	refresh_ui()
	emit_equipped_signal()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("open_inventory"):
		is_inventory_open = !is_inventory_open
		inventory_container.visible = is_inventory_open
		hotbar_container.visible = !is_inventory_open
		
		first_selected_slot_index = -1
		
		refresh_ui()

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			active_slot_index = posmod(active_slot_index -1, hotbar_slots)
			refresh_ui()
			emit_equipped_signal()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			active_slot_index = posmod(active_slot_index +1, hotbar_slots)
			refresh_ui()
			emit_equipped_signal()

func refresh_ui():
	for child in hotbar_container.get_children():
		child.queue_free()
	for child in inventory_container.get_children():
		child.queue_free()

	if is_inventory_open:
		for i in range(inventory_slots):
			create_slot_in(inventory_container, i)
	else:
		for i in range(hotbar_slots):
			create_slot_in(hotbar_container, i)
		
func create_slot_in(container, index):
	var slot_data = Inventory.slots[index]
	var new_slot = slot_scene.instantiate()
	container.add_child(new_slot)
	
	new_slot.slot_clicked.connect(_on_slot_clicked)
	new_slot.find_child("SelectionRect").visible = (index == active_slot_index)
			
	if slot_data["id"] != "":
		var item = DataManager.get_item(slot_data["id"])
		var item_name = item.get("name", "NULL")
		new_slot.tooltip_text = str(item_name)
		
		update_slot_visuals(new_slot, slot_data)
	else:
		new_slot.tooltip_text = ""

func update_slot_visuals(slot_ui, slot_data):
	var item_id = slot_data["id"]
	var amount = slot_data["amount"]
	var item = DataManager.get_item(item_id)
	
	var icon_rect = slot_ui.find_child("Icon")
	var path = "res://" + item.tile.file.replace("../", "")
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(path)
	var ts_base = Vector2i(item.get("tile_size"), item.get("tile_size"))
	
	var pos_x = item.tile.x * ts_base.x
	var pos_y = item.tile.y * ts_base.y
			
	var region_w = item.tile_width * ts_base.x
	var region_h = item.tile_height * ts_base.y
	
	atlas_tex.region = Rect2(pos_x, pos_y, region_w, region_h)
	icon_rect.texture = atlas_tex
	
	var label = slot_ui.find_child("AmountLabel")
	if not label: print("No amount label found!")
	label.text = str(amount) if amount > 1 else ""
	
func emit_equipped_signal():
	var active_slot_data = Inventory.slots[active_slot_index]
	item_equipped.emit(active_slot_data["id"])

func update_health_bar(current_hp, max_hp):
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func _on_slot_clicked(index):
	if first_selected_slot_index == -1 and not Inventory.slots[index].id == "":
		first_selected_slot_index = index
	else:
		Inventory.swap_slot(first_selected_slot_index, index)
		first_selected_slot_index = -1
		refresh_ui()
