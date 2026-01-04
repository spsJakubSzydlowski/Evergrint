extends Node

signal inventory_updated

var slots_amount: int
var slots = []

var inventory_full = false

func _ready() -> void:
	var stats = DataManager.get_full_entity_data("player")
	slots_amount = stats.get("inventory_slots", 8)

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
	
	inventory_updated.emit()

func has_free_space():
	for slot in slots:
		if slot["id"] == "":
			return true
	return false

func swap_slot(index_a, index_b):
	var temp = slots[index_a]
	slots[index_a] = slots[index_b]
	slots[index_b] = temp
	inventory_updated.emit()
