extends CharacterBody2D

const WEAPON_TYPE_MELEE = 0
const WEAPON_TYPE_RANGED = 1

enum MoveState { IDLE, MOVE, DASH }
enum ActionState { NONE, ATTACK, STUNNED, DEAD }

var current_move_state : MoveState = MoveState.IDLE
var current_action_state : ActionState = ActionState.NONE

var tile_map = null
var object_layer = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var hand: Node2D = $WeaponPivot/Hand
@onready var hand_sprite: Sprite2D = $WeaponPivot/Hand/Sprite2D
@onready var animation_player: AnimationPlayer = $WeaponPivot/Hand/AnimationPlayer
@onready var weapon_collision_shape: CollisionShape2D = $WeaponPivot/Hand/HitArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var invincibility_frames: Timer = $invincibility_frames
@onready var dash_cooldown_timer: Timer = $dash_cooldown

#region Movement Variables
var move_speed : float
var acceleration = 1500.0
var dash_velocity = 200.0
var dash_duration = 0.1
var dash_cooldown = 1

var knockback_velocity = Vector2.ZERO
#endregion

var ui: CanvasLayer = null
var can_be_hit : bool = true

var is_dead = false

var can_turn : bool = true
var can_attack : bool = true
var can_dash : bool = true

var max_hp : int
var current_hp : int

var stun_time: float = 0.4

var hit_entities = []

func _ready() -> void:
	velocity = Vector2.ZERO
	tile_map = get_tree().get_first_node_in_group("tilemap")
	object_layer = get_tree().get_first_node_in_group("objectmap")
	
	dash_cooldown_timer.wait_time = dash_cooldown
	
	setup_camera_limits()

func initialize():
	var player = DataManager.get_entity("player")

	if player == null:
		print("Error: ID ", player, " doesnt exist in database!")
		return
	
	ui = get_tree().get_first_node_in_group("ui")
	if ui != null:
		ui.connect("item_equipped", _on_inventory_canvas_item_equipped)
		
	name = player.id
	
	var anim_path = "res://sprite_frames/player.tres"
	if FileAccess.file_exists(anim_path):
		var new_frames = load(anim_path)
		sprite.sprite_frames = new_frames
		sprite.play("spawn")
	else:
		print("Animation was not found")
		
	var stats = DataManager.get_full_entity_data("player")
	max_hp = stats.get("max_hp", 100)
	current_hp = max_hp
	
	move_speed = stats.get("move_speed", 100.0)
	
	Signals.player_health_changed.emit(current_hp, max_hp)

func play_anim(anim_name: String, sprite_node):
	if has_node("AnimatedSprite2D"):
		if sprite_node.sprite_frames.has_animation(anim_name):
			sprite_node.play(anim_name)

func setup_camera_limits():
	var tile_size = 16
	var world_width = Global.world_width * tile_size
	var world_height = Global.world_height * tile_size
	
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = world_width
	camera.limit_bottom = world_height

func _physics_process(delta: float) -> void:
	match current_move_state:
		MoveState.DASH:
			pass
		MoveState.IDLE, MoveState.MOVE:
			velocity = move()
	
	match current_action_state:
		ActionState.DEAD:
			velocity = Vector2.ZERO
		ActionState.STUNNED:
			velocity.move_toward(Vector2.ZERO, acceleration * delta)
	
	var final_velocity = velocity + knockback_velocity
	
	var old_velocity = velocity
	velocity = final_velocity

	move_and_slide()
	
	velocity = old_velocity

func _unhandled_input(event: InputEvent) -> void:
	if current_action_state == ActionState.DEAD:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_interact_input()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_handle_action_input()
			
	if event.is_action_pressed("heal"):
		_handle_quick_heal()
	
	if event.is_action_pressed("attack"):
		change_action_state(ActionState.ATTACK)
		
	if event.is_action_pressed("dash"):
		if can_dash:
			change_move_state(MoveState.DASH)

func change_move_state(new_state: MoveState):
	if current_move_state == new_state: return
	
	current_move_state = new_state
	
	match current_move_state:
		MoveState.IDLE:
			pass
		MoveState.MOVE:
			move()
		MoveState.DASH:
			_on_player_dash()

func change_action_state(new_state: ActionState):
	if current_action_state == new_state: return
	
	current_action_state = new_state
	
	match current_action_state:
		ActionState.NONE:
			pass
		ActionState.ATTACK:
			attack(Inventory.current_equipped_id)
		ActionState.STUNNED:
			_on_player_stunned()
		ActionState.DEAD:
			_on_player_dead()

func move():
	var delta = get_process_delta_time()
	
	var direction := Input.get_vector("a", "d", "w", "s").normalized()
	
	if direction:
		velocity = velocity.move_toward(direction * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)

	if direction.x < 0 and can_turn:
		sprite.flip_h = true
	
	if direction.x > 0 and can_turn:
		sprite.flip_h = false
		
	var rect = Rect2i(0, 0, Global.world_width, Global.world_height)
	var tile_size = 16
	
	var limit_left = rect.position.x * tile_size
	var limit_top = rect.position.y * tile_size
	var limit_right = rect.end.x * tile_size
	var limit_bottom = rect.end.y * tile_size
	
	var player_height_half = 12
	var player_width_half = 8
	
	global_position.x = clamp(global_position.x, limit_left + player_width_half, limit_right - player_width_half)
	global_position.y = clamp(global_position.y, limit_top + player_height_half, limit_bottom)
	
	return velocity

func _handle_attack_input():
	if current_move_state in [MoveState.IDLE, MoveState.MOVE]:
		if Inventory.current_equipped_id != "":
			change_action_state(ActionState.ATTACK)

func _handle_interact_input():
	var mouse_pos = get_global_mouse_position()
	var tile_pos = object_layer.local_to_map(mouse_pos)

	var data = object_layer.get_cell_tile_data(tile_pos)

	if data and data.get_custom_data("is_sinkhole"):
		if global_position.distance_to(mouse_pos) > 200.0: return
		Global.save_player_position()

		if get_tree().current_scene.name == "main":
			Global.transition_to("underground")
		else:
			Global.transition_to("surface")

func _handle_action_input():
	var mouse_pos = get_global_mouse_position()
	var distance = global_position.distance_to(mouse_pos)
	var item_id = Inventory.current_equipped_id
	
	var consumable_stats = DataManager.get_consumable_stats(item_id)
	var weapon_stats = DataManager.get_weapon_stats(item_id)

	if consumable_stats:
		_handle_consumable_logic(consumable_stats, item_id)
		return
	
	if weapon_stats:
		_handle_mining_logic(weapon_stats, mouse_pos, distance)

func _handle_consumable_logic(consumable_stats, item_id):
	var boss_to_spawn = consumable_stats.get("boss_to_spawn")
	
	if boss_to_spawn:
		if Global.living_boss: return
		
		var direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		var spawn_pos = global_position + direction * 200
		
		var boss = await DataManager.spawn_entity(boss_to_spawn, spawn_pos)
		if boss:
			Inventory.remove_item(item_id, 1)
			AudioManager.play_sfx("boss_summon")
	else:
		if heal(consumable_stats.get("hp_to_heal", 0)):
			Inventory.remove_item(item_id, 1)
			AudioManager.play_sfx("food_crunch")

func _handle_mining_logic(weapon_stats, mouse_pos, distance):
	var tile_pos = object_layer.local_to_map(mouse_pos)
	var tile_data = object_layer.get_cell_tile_data(tile_pos)
	
	if tile_data and current_action_state != ActionState.ATTACK:
		var tool_range = weapon_stats.get("tool_range", 0)
		var is_in_distance = distance <= tool_range
		
		MiningManager.damage_block(
			mouse_pos,
			is_in_distance,
			weapon_stats.get("tool_type"),
			weapon_stats.get("tool_power", 0)
		)

func attack(item_id):
	if not can_attack:
		change_move_state(MoveState.IDLE)
		return
	
	var stats = DataManager.get_weapon_stats(item_id)
	if stats == {}:
		change_move_state(MoveState.IDLE)
		return
	
	can_attack = false
	
	hit_entities.clear()
	hand.visible = true
	weapon_collision_shape.disabled = false

	if stats.get("weapon_type") == WEAPON_TYPE_MELEE:
		hand_sprite.rotation = deg_to_rad(45)
		melee_attack(stats)
		await animation_player.animation_finished
		animation_player.play("RESET")
	elif stats.get("weapon_type") == WEAPON_TYPE_RANGED:
		var projectile = Inventory.get_equipped_ammo()
		if projectile:
			hand_sprite.rotation = 0
			ranged_attack(stats, projectile)
			await get_tree().create_timer(0.5).timeout
	
	weapon_collision_shape.disabled = true
	hand.visible = false
	can_attack = true
	
	if current_action_state not in [ActionState.DEAD, ActionState.STUNNED]:
		change_action_state(ActionState.NONE)
		change_move_state(MoveState.IDLE)

func melee_attack(stats):
	var mouse_position = get_global_mouse_position()
	
	weapon_pivot.look_at(mouse_position)
	var angle = wrapf(weapon_pivot.rotation_degrees, -180, 180)
	
	if abs(angle) > 95:
		weapon_pivot.scale.y = -1
	elif abs(angle) < 85:
		weapon_pivot.scale.y = 1

	animation_player.speed_scale = stats.get("attack_speed", 1.0)
	animation_player.play(stats.get("anim_name", "attack_swing_light"))
	
	AudioManager.play_sfx("sword_swing")

func ranged_attack(stats, projectile):
	var mouse_position = get_global_mouse_position()
	weapon_pivot.look_at(mouse_position)
	
	var direction = Vector2.RIGHT.rotated(weapon_pivot.rotation)
	
	if projectile:
		var is_projectile_from_player = true
		var projectile_spawn_pos = hand_sprite.global_position + (direction * 20.0)
		DataManager.spawn_projectile(projectile, projectile_spawn_pos, stats, direction, is_projectile_from_player)
		Inventory.remove_item(projectile, 1)
		
		AudioManager.play_sfx("bow_release")

func _on_inventory_canvas_item_equipped(item_id: String) -> void:
	Inventory.current_equipped_id = item_id
	
	if item_id == "":
		hand_sprite.texture = null
		return
	
	var item = DataManager.get_item(item_id)
	var stats = DataManager.get_weapon_stats(item_id)

	if stats:
		var hitbox_x = stats.get("hitbox_x")
		var hitbox_y = stats.get("hitbox_y")
		
		var offsex_x = stats.get("offset_x")

		weapon_collision_shape.shape.size = Vector2(hitbox_x, hitbox_y)
		weapon_collision_shape.position = Vector2(weapon_collision_shape.shape.size.x / 2 + offsex_x, 0)
		var path = "res://" + item.tile.file.replace("../", "")
		
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = load(path)
		var ts_base = Vector2i(item.get("tile_size"), item.get("tile_size"))
		
		var pos_x = item.tile.x * ts_base.x
		var pos_y = item.tile.y * ts_base.y
				
		var region_w = item.tile_width * ts_base.x
		var region_h = item.tile_height * ts_base.y
		
		atlas_tex.region = Rect2(pos_x, pos_y, region_w, region_h)
		hand_sprite.texture = atlas_tex
		
		if stats.get("weapon_type") == WEAPON_TYPE_MELEE:
			hand_sprite.offset = Vector2(0, -region_h)
		else:
			hand_sprite.offset = Vector2(region_w / 2, -region_h / 2)
	else:
		hand_sprite.texture = null

func take_hit(damage, knockback, source_pos):
	if is_dead or not can_be_hit: return
	
	current_hp -= damage
	Signals.player_health_changed.emit(current_hp, max_hp)
	can_be_hit = false
	invincibility_frames.start()
	
	var tween = create_tween()
	sprite.modulate = Color(10, 10, 10, 0.5)
	
	tween.tween_interval(0.06)
	tween.tween_callback(func():
		sprite.modulate = Color(1, 1, 1, 1)
	)
	
	AudioManager.play_sfx("player_hit")
	
	if current_hp <= 0:
		die()
		return
	
	apply_knockback(knockback, source_pos)

func _handle_quick_heal():
	var equipped_consumable_id = Inventory.get_heal()
	var consumable_stats = DataManager.get_consumable_stats(equipped_consumable_id)
	
	if not consumable_stats: return
	
	if heal(consumable_stats.get("hp_to_heal")):
		AudioManager.play_sfx("food_crunch")
		Inventory.remove_item(equipped_consumable_id, 1)

func heal(hp_to_heal):
	var success = false
	if is_dead: return success
	
	if current_hp >= max_hp: return success
	
	current_hp += hp_to_heal
	Signals.player_health_changed.emit(current_hp, max_hp)
	
	success = true
	return success

func _on_player_dash():
	velocity = Vector2.ZERO
	can_dash = false
	dash_cooldown_timer.start(dash_cooldown)
	
	var direction := Input.get_vector("a", "d", "w", "s").normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	
	velocity = direction * dash_velocity
	
	await get_tree().create_timer(dash_duration).timeout
	
	if current_move_state == MoveState.DASH:
		change_move_state(MoveState.IDLE)

func _on_player_stunned():
	var timer = get_tree().create_timer(stun_time)
	await timer.timeout
	
	if current_action_state == ActionState.STUNNED:
		change_move_state(MoveState.IDLE)

func _on_player_dead():
	Global.is_player_dead = true
	visible = false
	velocity = Vector2.ZERO
	
	Signals.player_died.emit()

func die():
	change_action_state(ActionState.DEAD)

func apply_knockback(knockback_amount, source_pos):
	var knockback_dir = source_pos.direction_to(global_position)
	knockback_velocity = knockback_dir * knockback_amount * 500
	change_action_state(ActionState.STUNNED)
	
	var tween = create_tween()
	tween.tween_property(self, "knockback_velocity", Vector2.ZERO, 0.15).set_trans(Tween.TRANS_BOUNCE)
	
	tween.tween_callback(func():
		if current_action_state != ActionState.DEAD:
			change_move_state(MoveState.MOVE)
	)

func _on_hit_area_area_entered(area: Area2D) -> void:
	var attackable = area.get_parent()
	
	if attackable in hit_entities or attackable.is_in_group("Player"):
		return
	
	if current_action_state != ActionState.ATTACK:
		return
	
	var item_stats = DataManager.get_weapon_stats(Inventory.current_equipped_id)
	if item_stats == {}:
		return
	
	if attackable.has_method("take_hit"):
		var damage_to_deal = item_stats.get("damage", 0)
		var knockback = item_stats.get("knockback", 0.0)
		
		attackable.take_hit(damage_to_deal, knockback, global_position)
		hit_entities.append(attackable)
	
	elif attackable.has_method("harvest"):
		var tool_type_enum = item_stats.get("tool_type")
		var tool_power = item_stats.get("tool_power")
	
		attackable.harvest(tool_type_enum, tool_power)
		hit_entities.append(attackable)

func _on_magnet_field_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot") and Inventory.has_free_space():
		area.start_magnetic_pull(self)

func respawn():
	velocity  = Vector2.ZERO
	if tile_map:
		var center_map_pos = Global.center_world_pos
		var center_world_pos = tile_map.map_to_local(center_map_pos)
		
		global_position = Vector2(center_world_pos)
		
	current_hp = max_hp
	visible = true
	Global.is_player_dead = false
	Signals.player_health_changed.emit(current_hp, max_hp)
	
	change_move_state(MoveState.IDLE)
	change_action_state(ActionState.NONE)

func _on_invincibility_frames_timeout() -> void:
	can_be_hit = true

func _on_dash_cooldown_timeout() -> void:
	change_move_state(MoveState.IDLE)
	can_dash = true
