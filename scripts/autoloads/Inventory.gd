extends Node

signal inventory_updated

var slots_amount = 10
var slots = []

func _ready() -> void:
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
