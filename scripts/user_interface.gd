extends CanvasLayer

signal item_equipped(item_id)

@onready var hotbar_container: HBoxContainer = $inventory_margin/hotbar
@onready var inventory_container: GridContainer = $inventory_margin/inventory

@onready var health_bar: TextureProgressBar = $MarginContainer/VBoxContainer/health_bar
@onready var health_label: Label = $MarginContainer/VBoxContainer/health_bar/health_label
@onready var compas_label: RichTextLabel = $MarginContainer/VBoxContainer/compas/compas_label

var first_selected_slot_index = -1
var selected_equip_slot_index = -1

var slot_scene = preload("res://scenes/UI/inventory_slot.tscn")
var active_slot_index = 0

var hotbar_slots = 10
var inventory_slots = 50

var is_inventory_open = false

var current_container

const ITEM_TYPE_NAMES = {
	0: "Weapon",
	1: "Tool",
	2: "Consumable",
	3: "Material",
	4: "Placeable",
	5: "Ammo"
}

var selected_slot_contents = null
var selected_slot_data = {"id": "", "amount": 0}

func _ready() -> void:
	Signals.play_world.connect(_on_play_world)
	Signals.player_health_changed.connect(update_health_bar)
	Signals.player_died.connect(_on_player_died)

	Inventory.inventory_updated.connect(on_inventory_updated)
	
	get_tree().tree_changed.connect(_on_world_changed)
	
	health_label.visible = false
	
	set_process(false)

func _on_play_world(_world_name):
	set_process(true)
	
	if current_container:
		for i in hotbar_container.get_children():
			i.queue_free()
		for i in inventory_container.get_children():
			i.queue_free()
				
	for i in range(hotbar_slots):
		create_slot_in(hotbar_container, i)
		
	for i in range(inventory_slots):
		create_slot_in(inventory_container, i)
	
	is_inventory_open = false
	inventory_container.visible = false
	hotbar_container.visible = true
	
	refresh_ui()
	await  get_tree().create_timer(0.1).timeout
	emit_equipped_signal()

func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	health_label.global_position = mouse_pos + Vector2(4, 4)
	
	if Global.current_tilemap:
		var relative_pos = Vector2i(Global.get_player_tilemap_position(Global.current_tilemap)) - Global.center_world_pos
		
		compas_label.text = get_compas_text(relative_pos)
		
	if selected_slot_contents:
		selected_slot_contents.global_position = mouse_pos

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
	if Global.is_player_dead or Global.world_name == "":
		return
		
	if Input.is_action_just_pressed("open_inventory"):
		toggle_inventory()
		
	for i in range(10):
		if Input.is_action_just_pressed("hotbar_" + str(i + 1)):
			active_slot_index = i
			refresh_ui()
			emit_equipped_signal()
			break
		
	if Input.is_action_just_pressed("stats"):
		compas_label.visible = not compas_label.visible
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			active_slot_index = posmod(active_slot_index -1, hotbar_slots)
			
			first_selected_slot_index = -1
			selected_equip_slot_index = -1
			if selected_slot_contents:
				selected_slot_contents.position = Vector2.ZERO
				selected_slot_contents.z_index = 0
				selected_slot_contents = null
				
			refresh_ui()
			emit_equipped_signal()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			active_slot_index = posmod(active_slot_index +1, hotbar_slots)
			
			first_selected_slot_index = -1
			selected_equip_slot_index = -1
			if selected_slot_contents:
				selected_slot_contents.position = Vector2.ZERO
				selected_slot_contents.z_index = 0
				selected_slot_contents = null
				
			refresh_ui()
			emit_equipped_signal()

func toggle_inventory():
	Tooltip.show_tooltips = true
	is_inventory_open = !is_inventory_open
	inventory_container.visible = is_inventory_open
	hotbar_container.visible = !is_inventory_open
	
	first_selected_slot_index = -1
	selected_equip_slot_index = -1
	if selected_slot_contents:
		selected_slot_contents.position = Vector2.ZERO
		selected_slot_contents.z_index = 0
		selected_slot_contents = null
	
	refresh_ui()

func refresh_ui():
	if is_inventory_open:
		current_container = inventory_container
	else:
		current_container = hotbar_container

	var slots = current_container.get_children()
	for i in range(slots.size()):
		var slot_ui = slots[i]
		var slot_data = Inventory.slots[i]
		
		if not active_slot_index > hotbar_slots:
			slot_ui.find_child("SelectionSprite").visible = (i == active_slot_index)
	
		if slot_data:
			update_slot_visuals(slot_ui, slot_data)
			update_tooltip_data(slot_data, slot_ui)

func create_slot_in(container, index):
	var new_slot = slot_scene.instantiate()
	container.add_child(new_slot)
	
	new_slot.slot_index = index
	
	new_slot.set_meta("item_data", null)
	new_slot.slot_clicked.connect(_on_slot_clicked)
	new_slot.mouse_entered.connect(_on_slot_mouse_entered.bind(new_slot))
	new_slot.mouse_exited.connect(_on_slot_mouse_exited)

func update_tooltip_data(slot_data, slot_ui):
	if slot_data and slot_data.get("id", "") != "":
		var item = DataManager.get_item(slot_data["id"])
		slot_ui.set_meta("item_data", item)
	else:
		slot_ui.set_meta("item_data", null)

func _on_slot_mouse_entered(slot):
	if slot.has_meta("item_data"):
		var item = slot.get_meta("item_data", null)
		if item:
			Tooltip.display_tooltip(item)
	
func _on_slot_mouse_exited():
	Tooltip.hide_tooltip()

func update_slot_visuals(slot_ui, slot_data):
	var icon_rect = slot_ui.find_child("Icon")
	var amount_label = slot_ui.find_child("AmountLabel")
	
	if not icon_rect or not amount_label: 
		printerr("Error occured while updating slot visuals. args:\n", slot_ui, "\n,", slot_data)
	
	if slot_data == null or slot_data["id"] == "":
		icon_rect.texture = null
		amount_label.text = ""
		return
	
	var item_id = slot_data["id"]
	var amount = slot_data["amount"]
	var item = DataManager.get_item(item_id)

	var image_path = "res://" + item.tile.file.replace("../", "")
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(image_path)
	
	var ts_base = Vector2i(item.get("tile_size"), item.get("tile_size"))
	
	var pos_x = item.tile.x * ts_base.x
	var pos_y = item.tile.y * ts_base.y
	
	var region_w = item.tile_width * ts_base.x
	var region_h = item.tile_height * ts_base.y
	
	atlas_tex.region = Rect2(pos_x, pos_y, region_w, region_h)
	
	icon_rect.texture = atlas_tex
	amount_label.text = str(int(amount)) if amount > 1 else ""
	
func emit_equipped_signal():
	if Inventory.slots != []:
		var active_slot_data = Inventory.slots[active_slot_index]
		item_equipped.emit(active_slot_data["id"])

func update_health_bar(current_hp, max_hp):
	health_bar.max_value = max_hp
	health_bar.value = current_hp

func _on_slot_clicked(slot_ui):
	var index = slot_ui.get_index()
	var slot_data = Inventory.slots[index]

	if first_selected_slot_index == -1 and selected_equip_slot_index == -1 and not slot_data.id == "":
		selected_slot_data = slot_data
		show_item_at_cursor(slot_ui)
		Inventory.slots[index] = {"id": "", "amount": 0}
		
		Tooltip.show_tooltips = false
		first_selected_slot_index = index
		active_slot_index = index
		
		AudioManager.play_sfx("inventory_slot_pop")
	
	elif selected_slot_data.id:
		Tooltip.show_tooltips = true
		
		if first_selected_slot_index != -1:
			Inventory.swap_slot(first_selected_slot_index, index)
			Inventory.slots[index] = selected_slot_data
			
			selected_slot_data = {"id": "", "amount": 0}
			selected_slot_contents.queue_free()
			selected_slot_contents = null
			first_selected_slot_index = -1

		elif selected_equip_slot_index != -1:

			if Inventory.slots[index].id == "":
				Inventory.slots[index] = selected_slot_data
				selected_slot_data = {"id": "", "amount": 0}
				selected_slot_contents.queue_free()
				selected_slot_contents = null
				
				selected_equip_slot_index = -1
			else:
				return
		
		AudioManager.play_sfx("inventory_slot_pop")
		
	refresh_ui()
	emit_equipped_signal()

func show_item_at_cursor(slot_ui):
	selected_slot_contents = slot_ui.find_child("Contents").duplicate()
	add_child(selected_slot_contents)
	selected_slot_contents.top_level = true
	selected_slot_contents.z_index = 100

func _on_world_changed():
	if get_tree():
		await get_tree().process_frame
		emit_equipped_signal()

func _on_player_died():
	if is_inventory_open:
		toggle_inventory()

func _on_health_bar_mouse_entered() -> void:
	health_label.visible = true

func _on_health_bar_mouse_exited() -> void:
	health_label.visible = false

func _on_health_bar_value_changed(value: float) -> void:
	health_label.text = str(int(value)) + "/" + str(int(health_bar.max_value))
