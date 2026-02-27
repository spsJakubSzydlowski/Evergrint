extends Control

var slot_scene = preload("res://scenes/UI/inventory_slot.tscn")
@onready var container: VBoxContainer = $container

var main_ui = null

const SLOTS_CONFIG = {
	"head": {},
	"chest": {},
	"legs": {},
	"feet": {}
}

var slot_nodes = {}

func _ready() -> void:
	Signals.play_world.connect(_on_play_world)
	
func _on_play_world(_world_name):
	main_ui = get_tree().get_first_node_in_group("ui")
	
	for child in container.get_children():
		child.queue_free()
		
	for type in SLOTS_CONFIG.keys():
		var new_slot = slot_scene.instantiate()
		container.add_child(new_slot)
		
		new_slot.set_meta("equipment_type", type)
		
		new_slot.mouse_entered.connect(_on_equipment_slot_mouse_entered.bind(new_slot))
		new_slot.mouse_exited.connect(_on_equipment_slot_mouse_exited)
		
		new_slot.slot_clicked.connect(_on_equipment_slot_clicked)

func _on_equipment_slot_mouse_entered(slot_ui):
	var slot_type = slot_ui.get_meta("equipment_type")
	var data = Equipment.equipped[slot_type]
	if data and data.id != "":
		var item = DataManager.get_item(data.id)
		Tooltip.display_tooltip(item)

func _on_equipment_slot_mouse_exited():
	Tooltip.hide_tooltip()

func _on_equipment_slot_clicked(slot_ui):
	var slot_type = slot_ui.get_meta("equipment_type")
	
	if Equipment.equipped[slot_type].id == "":
		_try_equip_item(slot_type, slot_ui)
	else:
		_try_unequip_item(slot_type, slot_ui)
		
func _try_equip_item(slot_type, equipment_slot_ui):
	var held_item_id = main_ui.selected_slot_data.id
	var held_item_amount = main_ui.selected_slot_data.amount
	var selected_contents = main_ui.selected_slot_contents
	
	if held_item_id:
		var armor_stats = DataManager.get_armor_stats(held_item_id)
		if not armor_stats: return
		
		var armor_slot_type = armor_stats.get("slot_type")
		
		if not armor_slot_type == slot_type: return
		
		Equipment.equipped[slot_type].id = held_item_id
		Equipment.equipped[slot_type].amount = held_item_amount
		
		main_ui.update_slot_visuals(equipment_slot_ui, Equipment.equipped[slot_type])
		main_ui.update_tooltip_data(Equipment.equipped[slot_type], equipment_slot_ui)
		
		if main_ui.selected_slot_contents:
			selected_contents.queue_free()
			selected_contents = null
		
		main_ui.selected_slot_data = {"id": "", "amount": 0}
		main_ui.first_selected_slot_index = -1
		main_ui.selected_equip_slot_index = -1
		Tooltip.show_tooltips = true
		
		AudioManager.play_sfx("inventory_slot_pop")
		
		main_ui.refresh_ui()

func _try_unequip_item(slot_type, equipment_slot_ui):
	var index = equipment_slot_ui.get_index()
	var held_item_id = main_ui.selected_slot_data.id
	
	if held_item_id: return
	
	if Equipment.equipped[slot_type].id != "":
		main_ui.selected_slot_data = Equipment.equipped[slot_type].duplicate()
		main_ui.show_item_at_cursor(equipment_slot_ui)
		
		Equipment.equipped[slot_type].id = ""
		Equipment.equipped[slot_type].amount = 0
				
		main_ui.update_slot_visuals(equipment_slot_ui, Equipment.equipped[slot_type])
		main_ui.update_tooltip_data(Equipment.equipped[slot_type], equipment_slot_ui)
		
		main_ui.selected_equip_slot_index = index
		Tooltip.show_tooltips = false
		
		AudioManager.play_sfx("inventory_slot_pop")
		
		main_ui.refresh_ui()
