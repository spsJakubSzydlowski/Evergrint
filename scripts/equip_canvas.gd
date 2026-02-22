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
		
		new_slot.slot_clicked.connect(_on_equipment_slot_clicked)
		
func _on_equipment_slot_clicked(slot_ui):
	var slot_type = slot_ui.get_meta("equipment_type")
	
	if main_ui.first_selected_slot_index != -1:
		_try_equip_item(slot_type)
		
func _try_equip_item(slot_type):
	var item_id = Inventory.slots[main_ui.first_selected_slot_index].id
	print("Trying to equip item: ", str(item_id), " in slot: ", str(slot_type))
