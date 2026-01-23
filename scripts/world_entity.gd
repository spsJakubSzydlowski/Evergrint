extends CharacterBody2D

const FACTION_HOSTILE = 0
const FACTION_PASSIVE = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var collision: CollisionShape2D = $hurt_box/CollisionShape2D

var entity = ""
var player = null
var loot_items = {}

#region Combat Variables
var is_dead := false

var is_boss = false

var max_hp : int
var current_hp: int

var attack_damage : int
var attack_range = 12.0
var start_aggro_range: float
var aggro_range: float
var aggro_range_mult = 1.5
var faction = null
var is_chasing = false

var got_hit = false
var is_acting = false

var last_attack = ""

#endregion

#region Movement Variables
var move_speed: float
var is_stunned = false

var idle_direction := Vector2.ZERO
#endregion

#region Timer Variables

var idle_timer := 0.0
var attack_timer := 0.0
var attack_cooldown = 1.0
#endregion

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	process_active_behaviour(delta)

func process_active_behaviour(delta):
	if faction == FACTION_HOSTILE and not is_stunned:
		if player and not is_dead:
			var distance = global_position.distance_to(player.global_position)
			
			if distance < attack_range and not player.is_dead:
				velocity = Vector2.ZERO
			elif distance <= aggro_range and not player.is_dead:
				var direction_raw = (player.global_position - global_position)
				var direction = direction_raw.normalized()

				move_speed = entity.get("move_speed")
				velocity = direction * move_speed
				
				if direction.x != 0:
					sprite.flip_h = direction.x < 0
			else:
				process_idle_behaviour(delta)
			
			attack_timer += delta
			if attack_timer >= attack_cooldown:
				if distance <= attack_range + 5:
					if not is_boss:
						deal_damage(player)
						attack_timer = 0.0
				if is_boss:
					if last_attack == "projectiles":
						is_acting = true
						AbilityManager.spawn_at_player(self, player)
						last_attack = "teleport"
					else:
						AbilityManager.projectile_burst("boulder", self, 8)
						last_attack = "projectiles"
				else:
					AbilityManager.projectile_burst("arrow", self, 6)
				attack_timer = 0.0
				
	if not is_acting:
		move_and_slide()

func process_idle_behaviour(delta: float):
	idle_timer -= delta
	if idle_timer <= 0:
		idle_timer = randf_range(2.0, 4.0)
		if randf() > 0.5:
			idle_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		else:
			idle_direction = Vector2.ZERO
			
	var idle_speed = entity.get("move_speed", 0.0) * 0.3
	velocity = idle_direction * idle_speed
	
	if idle_direction.x != 0:
		sprite.flip_h = idle_direction.x < 0

func initialize(entity_id: String):
	entity = DataManager.get_entity(entity_id)
	
	if entity == null:
		print("Error: ID ", entity_id, " doesnt exist in database!")
		return
	
	name = entity.id
	collision.shape.size = Vector2(entity.get("hitbox_x"), entity.get("hitbox_y"))
	var anim_path = "res://sprite_frames/" + entity_id + ".tres"
	if FileAccess.file_exists(anim_path):
		var new_frames = load(anim_path)
		sprite.sprite_frames = new_frames
		sprite.play("spawn")
	else:
		print("Animation was not found")

	var stats = DataManager.get_full_entity_data(entity_id)
	is_boss = stats.get("is_boss", false)
	max_hp = stats.get("max_hp", 1)
	current_hp = max_hp
	health_bar.max_value = max_hp
	
	if is_boss:
		health_bar.position.y *= 2
	
	faction = stats.get("faction")
	start_aggro_range = stats.get("aggro_range", 100.0)
	aggro_range = start_aggro_range
	
	attack_damage = stats.get("attack_damage", 0)
	
	var table_id= stats.get("loot_ref")
	loot_items = DataManager.get_loot_table_items(table_id)
	
	play_anim("spawn", sprite)

func _on_world_entity_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		deal_damage(body)

func take_hit(amount: int, knockback: float, source_pos):
	if is_dead: return
	
	if got_hit == false:
		aggro_range = start_aggro_range * aggro_range_mult
		got_hit = true

	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		
	current_hp -= amount
	update_heath_bar()
	
	if current_hp < (max_hp * 0.5) and is_boss:
		sprite.modulate = Color(2, 0.5, 0.5)
	
	if current_hp <= 0:
		die()
		return
	
	if not is_boss:
		is_stunned = true
		apply_knockback(knockback, source_pos)
		

func apply_knockback(knockback, source_pos):
	var knockback_dir = source_pos.direction_to(global_position)
	var target_pos = global_position + (knockback_dir * knockback * 20.0)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_BOUNCE)
	
	await get_tree().create_timer(0.2).timeout
	is_stunned = false
	
func die():
	is_dead = true
	drop_loot()
	queue_free()

func deal_damage(body):
	if body.has_method("take_hit") and body.can_be_hit:
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

func play_anim(anim_name: String, sprite_node):
	if has_node("AnimatedSprite2D"):
		if sprite_node.sprite_frames.has_animation(anim_name) and sprite_node.animation != anim_name:
			sprite_node.play(anim_name)
