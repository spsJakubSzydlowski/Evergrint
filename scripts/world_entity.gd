extends CharacterBody2D

const FACTION_HOSTILE = 0
const FACTION_PASSIVE = 1

@onready var sprite: Sprite2D = $Sprite2D
@onready var health_bar: TextureProgressBar = $HealthBar

var entity = ""

var player = null

var max_hp : int
var current_hp: int

var attack_damage : int

var attack_range = 12.0

var aggro_range: float
var faction = null

var move_speed: float
var is_stunned = false

var loot_items = {}

var is_dead := false

var is_chasing = false

var idle_timer := 0.0
var attack_timer := 0.0

var attack_cooldown = 1.0

var idle_direction := Vector2.ZERO

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	process_active_behaviour(delta)

func process_active_behaviour(delta):
	if faction == FACTION_HOSTILE and not is_stunned:
		if player and not is_dead:
			var distance = global_position.distance_to(player.global_position)
			
			if distance < attack_range:
				velocity = Vector2.ZERO
			elif distance <= aggro_range:
				var direction_raw = (player.global_position - global_position)
				var direction = direction_raw.normalized()
				
				move_speed = entity.get("move_speed")
				velocity = direction * move_speed
				
				if direction.x != 0:
					sprite.flip_h = direction.x < 0
			else:
				process_idle_behaviour(delta)
				
			if distance <= attack_range + 5:
				attack_timer += delta
				if attack_timer >= attack_cooldown:
					deal_damage(player)
					attack_timer = 0.0
			else:
				attack_timer = 0.0
				
		move_and_slide()

func process_idle_behaviour(delta: float):
	idle_timer -= delta
	if idle_timer <= 0:
		idle_timer = randf_range(2.0, 4.0)
		if randf() > 0.5:
			idle_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		else:
			idle_direction = Vector2.ZERO
			
	var idle_speed = entity.get("move_speed", 50.0) * 0.3
	velocity = idle_direction * idle_speed
	
	if idle_direction.x != 0:
		sprite.flip_h = idle_direction.x < 0

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
			
			var ts_base = Vector2(16, 16)
			
			var pos_x = entity.tile.x * ts_base.x
			var pos_y = entity.tile.y * ts_base.y
			
			var region_w = entity.tile_width * ts_base.x
			var region_h = entity.tile_height * ts_base.y
			
			sprite.region_rect = Rect2(pos_x, pos_y, region_w, region_h)
	
	var stats = DataManager.get_full_entity_data(entity_id)
	max_hp = stats.get("max_hp", 1)
	current_hp = max_hp
	health_bar.max_value = max_hp
	
	faction = stats.get("faction")
	aggro_range = stats.get("aggro_range", 100.0)
	
	attack_damage = stats.get("attack_damage", 0)
	
	var table_id= stats.get("loot_ref")
	loot_items = DataManager.get_loot_table_items(table_id)

func _on_world_entity_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		deal_damage(body)

func take_hit(amount: int, source_pos):
	if is_dead: return
		
	is_stunned = true
	
	var knockback_dir = source_pos.direction_to(global_position)
	var target_pos = global_position + (knockback_dir * 20.0)
	var tween = create_tween()
	
	if current_hp - amount > 0:
		tween.parallel().tween_property(self, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_BOUNCE)
	
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
	current_hp -= amount
	update_heath_bar()
	
	if current_hp <= 0:
		die()
	
	await get_tree().create_timer(0.2).timeout
	is_stunned = false
	
func die():
	is_dead = true
	drop_loot()
	queue_free()

func deal_damage(body):
	if body.has_method("take_hit"):
		var direction_to_player = global_position.direction_to(player.global_position)
		var dash_vector = direction_to_player * 10.0
		
		var tween = create_tween()
		tween.tween_property(sprite, "position", dash_vector, 0.05)
		tween.tween_property(sprite, "position", Vector2.ZERO, 0.15)
		
		body.take_hit(attack_damage)

func drop_loot():
	
	if loot_items == null:
		return

	for entry in loot_items:
		var roll = randf_range(0, 100)
		var chance = entry.get("weight", 0)
		
		if roll <= chance:
			var item_id = entry.get("item")
			var amount = randi_range(entry.get("amount_min", 1), entry.get("amount_max", 1))
			for i in range(amount):
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
