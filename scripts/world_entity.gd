extends CharacterBody2D

const FACTION_HOSTILE = 0
const FACTION_PASSIVE = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: TextureProgressBar = $HealthBar

var entity = ""

var player = null

var max_hp : int
var current_hp: int
var is_dead = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	if entity.get("faction") == FACTION_HOSTILE:
		if player and not is_dead:
			var direction = (player.global_position - global_position).normalized()
			
			var move_speed = entity.get("move_speed")
			velocity = direction * move_speed
			
			move_and_slide()
			
			if direction.x != 0:
				sprite.flip_h = direction.x < 0

func initialize(entity_id: String):
	entity = DataManager.get_entity(entity_id)
	
	if entity == null:
		print("Error: ID ", entity_id, " doesnt exist in database!")
		return
	
	name = entity.id
	
	if entity.has("tile"):
		var raw_path = entity.tile.file
		var clean_path = "res://" + raw_path.replace("../", "")
		
		var tex = load(clean_path)
		if tex:
			sprite.texture = tex
			sprite.region_enabled = true
			
			var ts = entity.tile_size
			sprite.region_rect = Rect2(entity.tile.x * ts, entity.tile.y * ts, ts, ts)
	
	max_hp = entity.get("max_hp", 1)
	current_hp = max_hp
	health_bar.max_value = max_hp

func _on_world_entity_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		deal_damage(body)
		

func take_hit(amount: int):
	if is_dead: return
	
	current_hp -= amount
	update_heath_bar()
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.RED, 0.1)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	drop_loot()
	queue_free()

func deal_damage(body):
	if body.has_method("take_hit"):
		var dmg = entity.get("damage", 0)
		body.take_hit(dmg)

func drop_loot():
	var table_id = entity.get("loot_ref")
	if table_id == "" or table_id == null:
		return
		
	var loot_items = DataManager.get_loot_table_items(table_id)
	for entry in loot_items:
		var roll = randf_range(0, 100)
		var chance = entry.get("weight", 0)
		
		if roll <= chance:
			var item_id = entry.get("item")
			DataManager.spawn_item(item_id, global_position, true)

func update_heath_bar():
	health_bar.visible = true
	health_bar.value = current_hp
	var health_ratio = float(current_hp) / float(health_bar.max_value)
	
	if health_ratio > 0.5:
		var factor = (health_ratio - 0.5) * 2.0
		health_bar.tint_progress = Color.YELLOW.lerp(Color.GREEN, factor)
	else:
		var factor = health_ratio * 2.0
		health_bar.tint_progress = Color.RED.lerp(Color.YELLOW, factor)
