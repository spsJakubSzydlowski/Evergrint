extends CharacterBody2D

var SPEED : float = 100.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var hand: Node2D = $Hand
@onready var hand_sprite: Sprite2D = $Hand/Sprite2D

var is_attacking := false

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("a", "d", "w", "s")
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	if direction.x < 0:
		sprite.flip_h = true
		if hand.position.x > 0:
			hand.position.x = -21
		hand_sprite.flip_h = true
	
	if direction.x > 0:
		sprite.flip_h = false
		if hand.position.x < 0:
			hand.position.x = 6
		hand_sprite.flip_h = false
		
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()
	move_and_slide()
	
func attack():
	is_attacking = true
	
	await get_tree().create_timer(0.3).timeout
	is_attacking = false


func _on_inventory_canvas_item_equipped(item_id: String) -> void:
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
	
