extends Node

signal inventory_updated

var current_equipped_id: String = ""

var slots_amount: int = 50
var slots = []

var inventory_full = false

func _ready() -> void:
	Signals.play_world.connect(_on_play_world.bind())
	
func _on_play_world(_world_name):
	slots = []
	for i in range(slots_amount):
		slots.append({"id": "", "amount": 0})

func add_item(item_id: String, amount: int = 1):
	var data = DataManager.get_item(item_id)
	if not data: return
	
	var stack_limit = data.get("stack_limit", 1)
	
	for slot in slots:
		if slot.id == item_id and slot.amount < stack_limit:
			var can_add = stack_limit - slot.amount
			var to_add = min(can_add, amount)
			slot.amount += to_add
			amount -= to_add
			if amount <= 0: break
	
	if amount > 0:
		for slot in slots:
			if slot.id == "":
				slot.id = item_id
				slot.amount = amount
				break
	
	update_inventory()

func remove_item(item_id: String, amount: int = 1):
	var data = DataManager.get_item(item_id)
	if not data: return
	
	var found = false
	
	for slot in slots:
		if slot.id == item_id:
			slot.amount -= amount
			found = true
			
			if slot.amount <= 0:
				slot.id = ""
				slot.amount = 0
			break

	if not found:
		print("item: ", item_id, " hasnt been found; Inventory.gd")
	
	update_inventory()

func has_free_space():
	for slot in slots:
		if slot["id"] == "":
			return true
	return false

func swap_slot(index_a, index_b):
	var temp = slots[index_a]
	slots[index_a] = slots[index_b]
	slots[index_b] = temp
	update_inventory()

func get_equipped_ammo():
	for slot in slots:
		if DataManager.get_projectile_stats(slot["id"]):
			return slot["id"]
	return null

func get_heal():
	for slot in slots:
		var consumable_stats = DataManager.get_consumable_stats(slot["id"])
		if consumable_stats and consumable_stats.get("hp_to_heal"):
			return slot["id"]
	return null

func update_inventory():
	inventory_updated.emit()
