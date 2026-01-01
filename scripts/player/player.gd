extends CharacterBody2D

var SPEED : float = 100.0
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

var max_hp := 10
var current_hp : int
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

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("a", "d", "w", "s")
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	if direction.x < 0 and can_turn:
		sprite.flip_h = true
	
	if direction.x > 0 and can_turn:
		sprite.flip_h = false
		
	if Input.is_action_just_pressed("attack") and not is_attacking:
		if current_equipped_id != "":
			attack(current_equipped_id)
	move_and_slide()
	
func attack(item_data):
	var item = DataManager.get_item(item_data)
	if item.get("action_ref") == null:
		return
	
	hit_entities.clear()
	is_attacking = true
	can_turn = false
	hand.visible = true
	weapon_collision_shape.disabled = false
	
	var mouse_position = get_global_mouse_position()
	
	weapon_pivot.look_at(mouse_position)
	var angle_rad = weapon_pivot.rotation
	#var angle_rad = deg_to_rad(angle)
	
	var radius_x = 10.0
	var radius_y = 5.0
	
	var pos_x = cos(angle_rad) * radius_x
	var pos_y = sin(angle_rad) * radius_y
	hand.position = Vector2(pos_x, pos_y)
	
	hand.rotation = angle_rad + PI/2
	
	var item_stats = DataManager.get_melee_stats(item.action_ref)
	
	animation_player.speed_scale = item_stats.attack_speed
	
	animation_player.play("attack_swing")

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
	
	var data = DataManager.get_item(item_id)
	if data.has("action_ref") and data.action_ref != "":
		weapon_collision_shape.shape.size = DataManager._get_item_hit_box(item_id)
		weapon_collision_shape.position = Vector2(weapon_collision_shape.shape.size.x / 2, 0)
		var path = "res://" + data.tile.file.replace("../", "")
		
		var atlas_tex = AtlasTexture.new()
		atlas_tex.atlas = load(path)
		var ts = data.tile_size
		atlas_tex.region = Rect2(data.tile.x * ts, data.tile.y * ts, ts, ts)
		hand_sprite.texture = atlas_tex
	else:
		hand_sprite.texture = null
		
func take_hit(damage):
	if is_dead: return
	
	current_hp -= damage
	
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	queue_free()

func _on_hit_area_area_entered(area: Area2D) -> void:
	var attackable = area.get_parent()
	
	if attackable in hit_entities:
		return
	
	if attackable.has_method("take_hit") and is_attacking and not attackable.is_in_group("Player"):
		
		if current_equipped_id == "": return
		
		var item_data = DataManager.get_item(current_equipped_id)
		var damage_to_deal = 1
		
		if item_data.has("action_ref") and item_data.action_ref != "":
			var stats = DataManager.get_melee_stats(item_data.action_ref)

			if stats:
				damage_to_deal = stats.damage

			attackable.take_hit(damage_to_deal)
			hit_entities.append(attackable)
			
	if attackable.has_method("harvest") and is_attacking and not attackable.is_in_group("Player"):
		if current_equipped_id == "": return
		
		var item_data = DataManager.get_item(current_equipped_id)
		
		if item_data.has("action_ref") and item_data.action_ref != "":
			var stats = DataManager.get_melee_stats(item_data.action_ref)
			
			if stats:
				var tool_type = stats.tool_type
				var tool_power = stats.tool_power

				attackable.harvest(tool_type, tool_power)
				hit_entities.append(attackable)

func _on_magnet_field_area_entered(area: Area2D) -> void:
	if area.is_in_group("loot"):
		area.start_magnetic_pull(self)
