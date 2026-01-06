extends CharacterBody2D

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
	if event.is_action_pressed("attack") and not is_attacking:
		if current_equipped_id != "":
			attack(current_equipped_id)

func move():
	if not is_dead:
		var direction := Input.get_vector("a", "d", "w", "s")
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
	
	var mouse_position = get_global_mouse_position()
	
	weapon_pivot.look_at(mouse_position)
	var angle_rad = wrapf(weapon_pivot.rotation_degrees, -180, 180)
	
	var radius_x = 50
	var radius_y = 5.0
	
	var pos_x = cos(angle_rad) * radius_x
	var pos_y = sin(angle_rad) * radius_y
	hand.position = Vector2(pos_x, pos_y)
	
	hand.rotation = angle_rad + PI/2

	if abs(angle_rad) > 95:
		weapon_pivot.scale.y = -1
	elif abs(angle_rad) < 85:
		weapon_pivot.scale.y = 1

	animation_player.speed_scale = stats.get("attack_speed", 1.0)
	animation_player.play(stats.get("anim_name", "attack_swing_light"))

	await animation_player.animation_finished 
	
	weapon_collision_shape.disabled = true
	hand.visible = false
	can_turn = true
	is_attacking = false

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
		
		var offset_x = stats.get("collision_offset_x", 0.0)
		var offset_y = stats.get("collision_offset_y", 0.0)
		
		weapon_collision_shape.shape.size = Vector2(hitbox_x, hitbox_y)
		weapon_collision_shape.position = Vector2(weapon_collision_shape.shape.size.x / 2 + offset_x, offset_y)
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
		hand_sprite.offset = Vector2(0, -region_h)
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
	var stats = DataManager.get_full_entity_data("player")
	global_position = Vector2(stats.get("spawn_point_x"), stats.get("spawn_point_y"))
	
	visible = true
	is_dead = false
	current_hp = max_hp
	can_turn = true
	is_attacking = false
	
	Signals.player_health_changed.emit(current_hp, max_hp)
	
