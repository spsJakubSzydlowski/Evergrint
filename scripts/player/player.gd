extends CharacterBody2D

const WEAPON_TYPE_MELEE = 0
const WEAPON_TYPE_RANGED = 1

var tile_map = null
var object_layer = null

@onready var sprite: Sprite2D = $Sprite2D

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var hand: Node2D = $WeaponPivot/Hand
@onready var hand_sprite: Sprite2D = $WeaponPivot/Hand/Sprite2D
@onready var animation_player: AnimationPlayer = $WeaponPivot/Hand/AnimationPlayer
@onready var weapon_collision_shape: CollisionShape2D = $WeaponPivot/Hand/HitArea/CollisionShape2D


var ui: CanvasLayer = null

var current_equipped_id : String = ""

var is_attacking := false
var can_turn = true

var max_hp : int
var current_hp : int

var move_speed : float

var is_dead = false

var hit_entities = []

func _ready() -> void:
	tile_map = get_tree().get_first_node_in_group("tilemap")
	object_layer = get_tree().get_first_node_in_group("objectmap")

func initialize():
	var player = DataManager.get_entity("player")

	if player == null:
		print("Error: ID ", player, " doesnt exist in database!")
		return
	
	ui = get_tree().get_first_node_in_group("ui")
	if ui != null:
		ui.connect("item_equipped", _on_inventory_canvas_item_equipped)
		
	name = player.id
	
	if player.has("tile"):
		var raw_path = player.tile.file
		var clean_path = "res://" + raw_path.replace("../", "")
		
		var tex = load(clean_path)
		if tex:
			sprite.texture = tex
			sprite.region_enabled = true
			
			var ts_base = Vector2(player.tile_size, player.tile_size)
			
			var pos_x = player.tile.x * ts_base.x
			var pos_y = player.tile.y * ts_base.y
			
			var region_w = player.tile_width * ts_base.x
			var region_h = player.tile_height * ts_base.y
			
			sprite.region_rect = Rect2(pos_x, pos_y, region_w, region_h)
			
	
	var stats = DataManager.get_full_entity_data("player")
	max_hp = stats.get("max_hp", 100)
	current_hp = max_hp
	
	move_speed = stats.get("move_speed", 100.0)
	
	Signals.player_health_changed.emit(current_hp, max_hp)

func _physics_process(_delta: float) -> void:
	move()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var mouse_pos = get_global_mouse_position()
		var tile_pos = object_layer.local_to_map(mouse_pos)
		
		var data = object_layer.get_cell_tile_data(tile_pos)

		if data and data.get_custom_data("is_sinkhole"):
			die()
		
	if event.is_action_pressed("attack") and not is_attacking:
		if current_equipped_id != "":
			attack(current_equipped_id)

func move():
	if not is_dead:
		var direction := Input.get_vector("a", "d", "w", "s").normalized()
		if direction:
			velocity.x = direction.x * move_speed
			velocity.y = direction.y * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.y = move_toward(velocity.y, 0, move_speed)
		
		if direction.x < 0 and can_turn:
			sprite.flip_h = true
		
		if direction.x > 0 and can_turn:
			sprite.flip_h = false
			
		move_and_slide()

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
			hand_sprite.rotation = deg_to_rad(0)
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
		DataManager.spawn_projectile(projectile, hand_sprite.global_position, stats, direction)
		Inventory.remove_item(projectile, 1)

func _on_inventory_canvas_item_equipped(item_id: String) -> void:
	current_equipped_id = item_id
	
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
		
func take_hit(damage):
	if is_dead: return

	current_hp -= damage
	Signals.player_health_changed.emit(current_hp, max_hp)
	
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	is_attacking = false
	
	visible = false
	
	Signals.player_died.emit()

func _on_hit_area_area_entered(area: Area2D) -> void:
	var attackable = area.get_parent()
	var item_stats = DataManager.get_weapon_stats(current_equipped_id)
	
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
		var tool_type = item_stats.get("tool_type")
		var tool_power = item_stats.get("tool_power")
	
		attackable.harvest(tool_type, tool_power)
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
	
