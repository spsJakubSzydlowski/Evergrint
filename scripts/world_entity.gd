extends CharacterBody2D

const FACTION_HOSTILE = 0
const FACTION_PASSIVE = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var collision: CollisionShape2D = $hurt_box/CollisionShape2D
@onready var visible_timer: Timer = $visible_timer

var entity = ""
var entity_name = ""
var player = null
var loot_items = {}
var entity_stats = {}

#region Combat Variables
var is_dead := false

var is_boss = false
var can_be_hit = true

var max_hp : int
var current_hp: int

var attack_damage : int
var knockback: float
var attack_range = 12.0
var start_aggro_range: float
var aggro_range: float
var aggro_range_mult = 1.5
var faction = null
var is_chasing = false

var got_hit = false
var is_acting = false

var behavior = {}
var behavior_index = 0

var stun_time = 0.2
#endregion

#region Movement Variables
var move_speed: float
var is_stunned = false

var idle_direction := Vector2.ZERO

var knockback_velocity = Vector2.ZERO
#endregion

#region Timer Variables

var idle_timer := 0.0
var attack_timer := 0.0
var attack_cooldown = 1.0
#endregion

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	process_active_behaviour()

func process_active_behaviour():
	if faction != FACTION_HOSTILE or is_dead or not player:
		return
		
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if not is_stunned:
		handle_movement(distance_to_player)
	else:
		velocity = knockback_velocity
		move_and_slide()
	
	handle_attacks(distance_to_player)
	
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

func handle_movement(distance_to_player):
	if player.current_action_state == player.ActionState.DEAD:
		velocity = Vector2.ZERO
		return
		
	if distance_to_player < attack_range:
		velocity = Vector2.ZERO
		deal_damage(player)
	elif distance_to_player <= aggro_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * entity.get("move_speed", 100)
		sprite.flip_h = direction.x < 0
	else:
		process_idle_behaviour(get_physics_process_delta_time())

func handle_attacks(distance_to_player):
	if player.current_action_state == player.ActionState.DEAD:
		if is_boss:
			Global.living_boss = false
			queue_free()
		return

	if distance_to_player <= aggro_range and not is_acting:
		execute_attack_logic()

func execute_attack_logic():
	if behavior.is_empty():
		return
	
	var current_step = behavior[behavior_index]
	
	match current_step["action"]:
		"shoot":
			var projectile_id = current_step.get("projectile_name", "arrow")
			var projectile_count = current_step.get("projectile_count", 1)
			AbilityManager.projectile_burst(projectile_id, self, projectile_count)
		"wait":
			var time = current_step.get("time", 1.0)
			AbilityManager.wait(self, time)
		"teleport":
			AbilityManager.spawn_at_player(self, player)
			
	behavior_index = (behavior_index + 1) % behavior.size()

func initialize(entity_id: String):
	entity = DataManager.get_entity(entity_id)
	
	if entity == null:
		print("Error: ID ", entity_id, " doesnt exist in database!")
		return
	
	name = entity.id
	entity_name = entity.id
	collision.shape.size = Vector2(entity.get("hitbox_x"), entity.get("hitbox_y"))

	var sprite_frames = SpriteFramesRegistry.get_frames(entity_id)
	if sprite_frames:
		sprite.sprite_frames = sprite_frames
		sprite.play("spawn")
	else:
		print("sprite_frame was not found for entity: " + entity_name)

	entity_stats = DataManager.get_full_entity_data(entity_id)
	is_boss = entity_stats.get("is_boss", false)
	max_hp = entity_stats.get("max_hp", 1)
	current_hp = max_hp
	health_bar.max_value = max_hp
	
	if is_boss:
		health_bar.position.y *= 2
	
	faction = entity_stats.get("faction")
	start_aggro_range = entity_stats.get("aggro_range", 100.0)
	aggro_range = start_aggro_range
	
	attack_damage = entity_stats.get("attack_damage", 0)
	knockback = entity_stats.get("knockback", 0)
	
	var table_id= entity_stats.get("loot_ref")
	loot_items = DataManager.get_loot_table_items(table_id)
	
	if Global.current_difficulty == Global.Difficulty.HARD:
		if entity_stats.has("behavior_hard"):
			behavior = entity_stats.get("behavior_hard", {})
		else:
			behavior = entity_stats.get("behavior_easy", {})
		
		max_hp = int(max_hp * Global.difficulty_multiplier)
		attack_damage = int(attack_damage * Global.difficulty_multiplier)
		
	elif Global.current_difficulty == Global.Difficulty.EASY:
		behavior = entity_stats.get("behavior_easy", {})
		
	play_anim("spawn", sprite)

func _on_world_entity_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		deal_damage(body)

func take_hit(amount: int, knockback_amount: float, source_pos):
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
	
	AudioManager.play_entity_sfx(entity.id, "hurt", global_position)

	if current_hp <= 0:
		die()
		return
	
	if not is_boss:
		var knockback_dir = (global_position - source_pos).normalized()
		apply_knockback(knockback_amount, knockback_dir)

func apply_knockback(knockback_amount, knockback_dir):
	knockback_velocity = knockback_dir * knockback_amount * 150.0

	var tween = create_tween()
	tween.tween_property(self, "knockback_velocity", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BOUNCE)
	
	is_stunned = true
	await get_tree().create_timer(stun_time).timeout
	is_stunned = false

func die():
	is_dead = true
		
	if is_boss:
		Signals.boss_died.emit(entity_name)
		AudioManager.play_sfx("boss_die", global_position)
		Global.living_boss = false
	
	drop_loot()
	queue_free()

func deal_damage(body):
	if body.has_method("take_hit") and body.can_be_hit:
		var direction_to_player = global_position.direction_to(player.global_position)
		var dash_vector = direction_to_player * 10.0
		
		var tween = create_tween()
		tween.tween_property(sprite, "position", dash_vector, 0.05)
		tween.tween_property(sprite, "position", Vector2.ZERO, 0.15)
		
		body.take_hit(attack_damage, knockback, global_position)

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

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	visible_timer.stop()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if not is_boss:
		visible_timer.start(60.0)

func _on_visible_timer_timeout() -> void:
	queue_free()
