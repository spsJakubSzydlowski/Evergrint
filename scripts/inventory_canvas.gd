extends CanvasLayer

signal item_equipped(item_id)

@onready var hotbar_container: HBoxContainer = $hotbar
@onready var health_bar: TextureProgressBar = $health_bar

var slot_scene = preload("res://scenes/UI/inventory_slot.tscn")
var active_slot_index = 0

var hotbar_slots = 10

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.health_changed.connect(update_health_bar)
		update_health_bar(player.current_hp, player.max_hp)
	
	Inventory.inventory_updated.connect(on_inventory_updated)
	refresh_ui()
	emit_equipped_signal()
	
func on_inventory_updated():
	refresh_ui()
	emit_equipped_signal()

func _input(event: InputEvent) -> void:
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
		
	for i in range(hotbar_slots):
		var slot_data = Inventory.slots[i]
		var new_slot = slot_scene.instantiate()
		hotbar_container.add_child(new_slot)
		
		new_slot.find_child("SelectionRect").visible = (i == active_slot_index)
		
		if slot_data["id"] != "":
			update_slot_visuals(new_slot, slot_data)

func update_slot_visuals(slot_ui, slot_data):
	var item_id = slot_data["id"]
	var amount = slot_data["amount"]
	var data = DataManager.get_item(item_id)
	
	var icon_rect = slot_ui.find_child("Icon")
	var path = "res://" + data.tile.file.replace("../", "")
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(path)
	var ts = data.tile_size
	atlas_tex.region = Rect2(data.tile.x * ts, data.tile.y * ts, ts, ts)
	icon_rect.texture = atlas_tex
	
	var label = slot_ui.find_child("AmountLabel")
	label.text = str(amount) if amount > 1 else ""

func emit_equipped_signal():
	var active_slot_data = Inventory.slots[active_slot_index]
	item_equipped.emit(active_slot_data["id"])

func update_health_bar(current_hp, max_hp):
	print("update")
	health_bar.max_value = max_hp
	health_bar.value = current_hp
