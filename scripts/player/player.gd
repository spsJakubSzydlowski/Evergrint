extends CharacterBody2D

var SPEED : float = 100.0
@onready var sprite: Sprite2D = $Sprite2D

@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var hand: Node2D = $WeaponPivot/Hand
@onready var hand_sprite: Sprite2D = $WeaponPivot/Hand/Sprite2D
@onready var animation_player: AnimationPlayer = $WeaponPivot/Hand/AnimationPlayer

var current_equipped_id : String = ""

var is_attacking := false
var can_turn = true

var max_hp := 10
var current_hp = max_hp

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
		weapon_pivot.scale.x = -1
	
	if direction.x > 0 and can_turn:
		sprite.flip_h = false
		weapon_pivot.scale.x = 1
		
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
	move_and_slide()
	
func attack():
	is_attacking = true
	can_turn = false
	hand.visible = true
	
	animation_player.play("attack_swing")
	await animation_player.animation_finished
	
	hand.visible = false
	can_turn = true
	is_attacking = false


func _on_inventory_canvas_item_equipped(item_id: String) -> void:
	current_equipped_id = item_id
	
	if item_id == "":
		hand_sprite.texture = null
		return
	
	var data = DataManager.get_item(item_id)

	var path = "res://" + data.tile.file.replace("../", "")
	
	var atlas_tex = AtlasTexture.new()
	atlas_tex.atlas = load(path)
	var ts = data.tile_size
	atlas_tex.region = Rect2(data.tile.x * ts, data.tile.y * ts, ts, ts)
	hand_sprite.texture = atlas_tex

func take_damage(damage):
	current_hp -= damage
	print(current_hp)

func _on_hit_area_area_entered(area: Area2D) -> void:
	if area.has_method("take_hit") and is_attacking:
		if current_equipped_id == "": return
		
		var item_data = DataManager.get_item(current_equipped_id)
		var damage_to_deal = 1
		
		if item_data.has("melee_ref") and item_data.melee_ref != "":
			var stats = DataManager.get_melee_stats(item_data.melee_ref)

			if stats:
				damage_to_deal = stats.damage

		area.take_hit(damage_to_deal)
		print("You hit an enemy for:", damage_to_deal)
