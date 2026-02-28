extends Node

const equipped_default = {
	"head": {"id": "", "amount": 0},
	"chest": {"id": "", "amount": 0},
	"legs": {"id": "", "amount": 0},
	"feet": {"id": "", "amount": 0}
}

var equipped = {
	"head": {"id": "", "amount": 0},
	"chest": {"id": "", "amount": 0},
	"legs": {"id": "", "amount": 0},
	"feet": {"id": "", "amount": 0}
}

const EQUIPMENT_TYPES = ["head", "chest", "legs", "feet"]

func get_armor_amount() -> int:
	var armor_amount = 0
	for slot in equipped:
		var id = equipped[slot]["id"]
		
		var armor_stats = DataManager.get_armor_stats(id)
		var amount = armor_stats.get("armor", 0)
		armor_amount += amount
	return armor_amount
