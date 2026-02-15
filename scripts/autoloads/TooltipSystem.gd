extends CanvasLayer

@onready var title_label: RichTextLabel = $PanelContainer/HBoxContainer/title_label
@onready var panel_container: PanelContainer = $PanelContainer
@onready var stats_label: RichTextLabel = $PanelContainer/HBoxContainer/stats_label
@onready var tip_label: RichTextLabel = $PanelContainer/HBoxContainer/tip_label
@onready var type_label: RichTextLabel = $PanelContainer/HBoxContainer/type_label

var show_tooltips = true

const ITEM_TYPE_NAMES = {
	0: "Weapon",
	1: "Tool",
	2: "Consumable",
	3: "Material",
	4: "Placeable",
	5: "Ammo"
}

func _ready() -> void:
	hide_tooltip()
	panel_container.reset_size()

func display_tooltip(item):
	if not show_tooltips:
		return

	var item_id = item.get("id")
	
	if not title_label:
		return
	
	stats_label.text = ""
	tip_label.text = ""
	
	title_label.text = item.get("name", "NULL")
	tip_label.text = item.get("tooltip", "")
	
	var item_type_id = int(item.get("type", 0))
	var type_str = ITEM_TYPE_NAMES.get(item_type_id, "NULL")
	
	type_label.text = type_str
	
	var weapon_stats = DataManager.get_weapon_stats(item_id)
	if not weapon_stats.is_empty():
		stats_label.text += "Damage: " + str(weapon_stats.get("damage", 0))
		stats_label.text += "\nSpeed: " + str(weapon_stats.get("attack_speed", 0))
		stats_label.text += "\nKnockback: " + str(weapon_stats.get("knockback", 0))
	
	var projectile_stats = DataManager.get_projectile_stats(item_id)
	if not projectile_stats.is_empty():
		stats_label.text += "Damage: " + str(projectile_stats.get("damage", 0))
	
	var consumable_stats = DataManager.get_consumable_stats(item_id)
	if consumable_stats:
		var hp_to_heal = consumable_stats.get("hp_to_heal", 0)
		if hp_to_heal:
			stats_label.text += "Heal: " + str(hp_to_heal)
	
	await get_tree().process_frame
	panel_container.reset_size()
	
	set_process(true)
	self.visible = true

func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	panel_container.global_position = mouse_pos + Vector2(8, 8)
	
func hide_tooltip():
	set_process(false)
	stats_label.text = ""
	type_label.text = ""
	tip_label.text = ""
	self.visible = false
