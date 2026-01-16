extends StaticBody2D

@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

const TOOL_TYPE_NONE = 1
const TOOL_TYPE_AXE = 2

var is_block = false

var sprite = null
var collision
var resource = null

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
	collision = get_node("hurt_box/CollisionShape2D")
	
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
	
	collision.shape.size = Vector2(resource.get("hitbox_x", 16), resource.get("hitbox_y", 16))
	max_hp = resource.get("hit_points", 1)
	current_hp = max_hp
	
	is_block = resource.get("is_block", false)
	
	prefered_tool_type = resource.get("tool_type", TOOL_TYPE_NONE)

func harvest(tool_type_enum, amount: int):
	if is_harvested: return
	
	for tool_type in tool_type_enum:
		if tool_type == prefered_tool_type:
			current_hp -= amount
			var tw = create_tween()
			tw.tween_property(sprite, "modulate", Color.RED, 0.1)
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
			
		if current_hp <= 0:
			die()

func die():
	is_harvested = true
	var map_pos = MiningManager.current_tilemap.local_to_map(global_position)
	var fixed_pos = Vector2i(map_pos)
	
	var world_id = Global.current_world_id
	if not Global.world_changes.has(world_id):
		Global.world_changes[world_id] = {}
		
	Global.world_changes[world_id][fixed_pos] = "removed"
	
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

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	set_process(true)
	set_physics_process(true)
	collision.disabled = false
	sprite.show()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	set_process(false)
	set_physics_process(false)
	collision.disabled = true
	sprite.hide()
