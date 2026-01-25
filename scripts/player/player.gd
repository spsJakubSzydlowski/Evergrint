extends CharacterBody2D

const WEAPON_TYPE_MELEE = 0
const WEAPON_TYPE_RANGED = 1

var tile_map = null
var object_layer = null

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var hand: Node2D = $WeaponPivot/Hand
@onready var hand_sprite: Sprite2D = $WeaponPivot/Hand/Sprite2D
@onready var animation_player: AnimationPlayer = $WeaponPivot/Hand/AnimationPlayer
@onready var weapon_collision_shape: CollisionShape2D = $WeaponPivot/Hand/HitArea/CollisionShape2D
@onready var camera: Camera2D = $Camera2D

#region Movement Variables
var move_speed : float
var acceleration = 400.0
#endregion

var ui: CanvasLayer = null
var can_be_hit : bool = true

var is_attacking : bool = false
var can_turn : bool = true

var max_hp : int
var current_hp : int

var is_dead : bool = false
var is_stunned: bool = false

var time_stunned: float = 0.4

var hit_entities = []

func _ready() -> void:
	tile_map = get_tree().get_first_node_in_group("tilemap")
	object_layer = get_tree().get_first_node_in_group("objectmap")
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
	var world_width = tile_map.get_used_rect().size.x * tile_size
	var world_height = tile_map.get_used_rect().size.y * tile_size
	
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = world_width
	camera.limit_bottom = world_height

func _physics_process(delta: float) -> void:
	if is_dead or is_stunned:
		return

	move(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var mouse_pos = get_global_mouse_position()
		var tile_pos = object_layer.local_to_map(mouse_pos)

		var data = object_layer.get_cell_tile_data(tile_pos)

		if data and data.get_custom_data("is_sinkhole"):
			Global.save_player_position()

			if get_tree().current_scene.name == "main":
				Global.transition_to("underground")
			else:
				Global.transition_to("surface")
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_pos = get_global_mouse_position()
		var tile_pos = object_layer.local_to_map(mouse_pos)
		
		var distance = global_position.distance_to(mouse_pos)
		
		var data = object_layer.get_cell_tile_data(tile_pos)
		
		if data:
			var item_stats = DataManager.get_weapon_stats(Inventory.current_equipped_id)
			var tool_type_enum
			var tool_power: int
			var tool_range: int
			var is_in_distance: bool
			
			if item_stats != {} and not is_attacking:
				tool_type_enum = item_stats.get("tool_type")
				tool_power = item_stats.get("tool_power", 0)
				tool_range = item_stats.get("tool_range", 0)
				is_in_distance = distance <= tool_range
				
				MiningManager.damage_block(mouse_pos, is_in_distance, tool_type_enum, tool_power)
			
	if event.is_action_pressed("attack") and not is_attacking:
		if Inventory.current_equipped_id != "":
			attack(Inventory.current_equipped_id)

func move(delta):
	var direction := Input.get_vector("a", "d", "w", "s").normalized()
	if direction:
		velocity = velocity.move_toward(direction * move_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
	
	if direction.x < 0 and can_turn:
		sprite.flip_h = true
	
	if direction.x > 0 and can_turn:
		sprite.flip_h = false
		
	move_and_slide()
	
	var rect = tile_map.get_used_rect()
	var tile_size = 16
	
	var limit_left = rect.position.x * tile_size
	var limit_top = rect.position.y * tile_size
	var limit_right = rect.end.x * tile_size
	var limit_bottom = rect.end.y * tile_size
	
	var player_height_half = 12
	var player_width_half = 8
	
	global_position.x = clamp(global_position.x, limit_left + player_width_half, limit_right - player_width_half)
	global_position.y = clamp(global_position.y, limit_top + player_height_half, limit_bottom)

func attack(item_id):
	var stats = DataManager.get_weapon_stats(item_id)
	
	if stats == {}:
		return
	
	hit_entities.clear()
	is_attacking = true
	can_turn = false
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
	can_turn = true
	is_attacking = false

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

func ranged_attack(stats, projectile):
	var mouse_position = get_global_mouse_position()
	weapon_pivot.look_at(mouse_position)
	
	var direction = Vector2.RIGHT.rotated(weapon_pivot.rotation)
	
	if projectile:
		var is_projectile_from_player = true
		DataManager.spawn_projectile(projectile, hand_sprite.global_position, stats, direction, is_projectile_from_player)
		Inventory.remove_item(projectile, 1)

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
	if is_dead: return
	
	current_hp -= damage
	Signals.player_health_changed.emit(current_hp, max_hp)
	can_be_hit = false
	
	if current_hp <= 0:
		die()
		return
	
	apply_knockback(knockback, source_pos)

func die():
	is_dead = true
	is_attacking = false
	
	visible = false
	Signals.player_died.emit()

func apply_knockback(knockback_amount, source_pos):
	var knockback_dir = source_pos.direction_to(global_position)
	var target_pos = global_position + (knockback_dir * knockback_amount * 20.0)
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.15).set_trans(Tween.TRANS_BOUNCE)
	
	is_stunned = true
	await get_tree().create_timer(time_stunned).timeout
	is_stunned = false
	
func _on_hit_area_area_entered(area: Area2D) -> void:
	var attackable = area.get_parent()
	var item_stats = DataManager.get_weapon_stats(Inventory.current_equipped_id)
	
	if attackable in hit_entities:
		return
	
	if attackable.has_method("take_hit") and is_attacking and not attackable.is_in_group("Player"):
		var damage_to_deal: int
		var knockback: float
		
		if item_stats != {}:
			damage_to_deal = item_stats.get("damage", 0)
			knockback = item_stats.get("knockback", 0.0)
			
			attackable.take_hit(damage_to_deal, knockback, global_position)
			hit_entities.append(attackable)
			
	if attackable.has_method("harvest") and is_attacking and not attackable.is_in_group("Player"):
		var tool_type_enum = item_stats.get("tool_type")
		var tool_power = item_stats.get("tool_power")
	
		attackable.harvest(tool_type_enum, tool_power)
		hit_entities.append(attackable)

func _on_magnet_field_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot") and Inventory.has_free_space():
		area.start_magnetic_pull(self)

func respawn():
	if tile_map:
		var rect = tile_map.get_used_rect()
		var center_map_pos = rect.position + (rect.size / 2)
		var center_world_pos = tile_map.map_to_local(center_map_pos)
		
		global_position = Vector2(center_world_pos)
		
	visible = true
	is_dead = false
	current_hp = max_hp
	can_turn = true
	is_attacking = false
	
	Signals.player_health_changed.emit(current_hp, max_hp)
	
func _on_invincibility_frames_timeout() -> void:
	can_be_hit = true
