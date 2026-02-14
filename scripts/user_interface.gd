extends CanvasLayer

signal item_equipped(item_id)

@onready var hotbar_container: HBoxContainer = $hotbar
@onready var health_bar: TextureProgressBar = $health_bar
@onready var inventory_container: GridContainer = $inventory
@onready var compas_label: RichTextLabel = $MarginContainer/compas/compas_label

var first_selected_slot_index = -1

var slot_scene = preload("res://scenes/UI/inventory_slot.tscn")
var active_slot_index = 0

var hotbar_slots = 10
var inventory_slots = 50

var is_inventory_open = false

const ITEM_TYPE_NAMES = {
	0: "Weapon",
	1: "Tool",
	2: "Consumable",
	3: "Material",
	4: "Placeable",
	5: "Ammo"
}

var selected_slot_contents = null

func _ready() -> void:
	Signals.player_health_changed.connect(update_health_bar)
	Signals.player_died.connect(_on_player_died)

	Inventory.inventory_updated.connect(on_inventory_updated)
	
	get_tree().tree_changed.connect(_on_world_changed)
	
	refresh_ui()
	emit_equipped_signal()

func _process(_delta: float) -> void:
	if Global.current_tilemap:
		var relative_pos = Vector2i(Global.get_player_tilemap_position(Global.current_tilemap)) - Global.center_world_pos
		
		compas_label.text = get_compas_text(relative_pos)
		
	if selected_slot_contents:
		var mouse_pos = get_viewport().get_mouse_position()
		selected_slot_contents.global_position = mouse_pos + Vector2(-8, -8)

func get_compas_text(relative_pos):
	var text_n_s = "0"
	var text_w_e = "0"
	
	if relative_pos.y < 0:
		text_n_s = str(abs(relative_pos.y)) + "N"
	elif relative_pos.y > 0:
		text_n_s = str(relative_pos.y) + "S"
	
	if relative_pos.x < 0:
		text_w_e = str(abs(relative_pos.x)) + "W"
	elif relative_pos.x > 0:
		text_w_e = str(relative_pos.x) + "E"
	
	if text_n_s == "" and text_w_e == "":
		return "0N 0E"
	
	return text_n_s + " " + text_w_e

func on_inventory_updated():
	refresh_ui()
	emit_equipped_signal()

func _input(event: InputEvent) -> void:
	if Global.is_player_dead:
		return
		
	if Input.is_action_just_pressed("open_inventory"):
		toggle_inventory()
		
	if Input.is_action_just_pressed("hotbar_1"):
		active_slot_index = 0
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_2"):
		active_slot_index = 1
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_3"):
		active_slot_index = 2
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_4"):
		active_slot_index = 3
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_5"):
		active_slot_index = 4
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_6"):
		active_slot_index = 5
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_7"):
		active_slot_index = 6
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_8"):
		active_slot_index = 7
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_9"):
		active_slot_index = 8
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("hotbar_10"):
		active_slot_index = 9
		refresh_ui()
		emit_equipped_signal()
		
	if Input.is_action_just_pressed("stats"):
		compas_label.visible = not compas_label.visible
		
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			active_slot_index = posmod(active_slot_index -1, hotbar_slots)
			refresh_ui()
			emit_equipped_signal()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			active_slot_index = posmod(active_slot_index +1, hotbar_slots)
			refresh_ui()
			emit_equipped_signal()
			
func toggle_inventory():
	Tooltip.show_tooltips = true
	is_inventory_open = !is_inventory_open
	inventory_container.visible = is_inventory_open
	hotbar_container.visible = !is_inventory_open
	
	first_selected_slot_index = -1
	
	refresh_ui()

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
	new_slot.find_child("SelectionSprite").visible = (index == active_slot_index)
			
	create_tooltip(slot_data, new_slot)

func create_tooltip(slot_data, new_slot):
	if slot_data["id"] != "":
		var item = DataManager.get_item(slot_data["id"])
		
		new_slot.set_meta("item_data", item)
		
		if not new_slot.mouse_entered.is_connected(_on_slot_mouse_entered):
			new_slot.mouse_entered.connect(_on_slot_mouse_entered.bind(new_slot))
			new_slot.mouse_exited.connect(_on_slot_mouse_exited)
			
		update_slot_visuals(new_slot, slot_data)
	else:
		new_slot.set_meta("item_data", null)

func _on_slot_mouse_entered(slot):
	var item = slot.get_meta("item_data")
	if item:
		Tooltip.display_tooltip(item)
		
func _on_slot_mouse_exited():
	Tooltip.hide_tooltip()

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
	label.text = str(int(amount)) if amount > 1 else ""
	
func emit_equipped_signal():
	var active_slot_data = Inventory.slots[active_slot_index]
	item_equipped.emit(active_slot_data["id"])

func update_health_bar(current_hp, max_hp):
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func _on_slot_clicked(index, slot_ui):
	var slot_data = Inventory.slots[index]
	if first_selected_slot_index == -1 and not slot_data.id == "":
		Tooltip.show_tooltips = false
		first_selected_slot_index = index
		show_item_at_cursor(slot_ui)
		AudioManager.play_sfx("inventory_slot_pop")
	elif not first_selected_slot_index == -1:
		Tooltip.show_tooltips = true
		Inventory.swap_slot(first_selected_slot_index, index)
		first_selected_slot_index = -1
		refresh_ui()
		AudioManager.play_sfx("inventory_slot_pop")

func show_item_at_cursor(slot_ui):
	selected_slot_contents = slot_ui.find_child("Contents")
	selected_slot_contents.z_index = 100

func _on_world_changed():
	if get_tree():
		await get_tree().process_frame
		emit_equipped_signal()

func _on_player_died():
	if is_inventory_open:
		toggle_inventory()
