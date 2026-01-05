extends StaticBody2D

const TOOL_TYPE_NONE = 0
const TOOL_TYPE_AXE = 1
const TOOL_TYPE_PICKAXE = 2

var sprite = null

var resource = ""

var player = null

var is_harvested = false

var max_hp : int
var current_hp: int

var prefered_tool_type = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func initialize(resource_id: String):
	resource = DataManager.get_resource(resource_id)

	if resource == null:
		print("Error: ID ", resource_id, " doesnt exist in database!")
		return
	
	name = resource.id
	
	sprite = get_node("Sprite2D")
	
	if resource.has("tile"):
		var raw_path = resource.tile.file
		var clean_path = "res://" + raw_path.replace("../", "")
		
		var tex = load(clean_path)
		if tex:
			sprite.texture = tex
			sprite.region_enabled = true
			
			var ts_base = Vector2(16, 16)
			
			var pos_x = resource.tile.x * ts_base.x
			var pos_y = resource.tile.y * ts_base.y
			
			var region_w = resource.tile_width * ts_base.x
			var region_h = resource.tile_height * ts_base.y
			
			sprite.region_rect = Rect2(pos_x, pos_y, region_w, region_h)
	
	max_hp = resource.get("hit_points", 1)
	current_hp = max_hp
	
	prefered_tool_type = resource.get("tool_type", TOOL_TYPE_NONE)

func harvest(tool_type, amount: int):
	if is_harvested: return
	
	if tool_type == prefered_tool_type:
		current_hp -= amount

		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color.RED, 0.1)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
		if current_hp <= 0:
			die()

func die():
	is_harvested = true
	drop_loot()
	queue_free()

func drop_loot():
	var table_id = resource.get("loot_ref")
	if table_id == "" or table_id == null:
		return
		
	var loot_items = DataManager.get_loot_table_items(table_id)
	for entry in loot_items:
		var roll = randf_range(0, 100)
		var chance = entry.get("weight", 0)
		
		if roll <= chance:
			var item_id = entry.get("item")
			var amount = randi_range(entry.get("amount_min"), entry.get("amount_max"))
			
			for i in range(amount):
				DataManager.spawn_item(item_id, global_position, true)
