extends Area2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var item = ""

var current_pull_speed = 10.0
var target_player = null

func _physics_process(delta: float) -> void:
	magnetic_pull(delta)

func initialize(item_id: String):
	item = DataManager.get_item(item_id)
	
	if item == null:
		print("Error: ID ", item_id, " doesnt exist in database!")
		return
	
	name = item.id
	
	if item.has("tile"):
		var raw_path = item.tile.file
		var clean_path = "res://" + raw_path.replace("../", "")
		
		var tex = load(clean_path)
		if tex:
			sprite.texture = tex
			sprite.region_enabled = true
			
			var ts_base = Vector2i(item.get("tile_size"), item.get("tile_size"))
			
			var pos_x = item.tile.x * ts_base.x
			var pos_y = item.tile.y * ts_base.y
			
			var region_w = item.tile_width * ts_base.x
			var region_h = item.tile_height * ts_base.y
			
			sprite.region_rect = Rect2(pos_x, pos_y, region_w, region_h)
	
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		collision.set_deferred("disabled", true)
		collect_item()

func collect_item():
	if Inventory.has_free_space():
		Inventory.add_item(item.id)
		queue_free()
	else:
		target_player = null

func magnetic_pull(delta):
	if target_player:
		await get_tree().create_timer(0.22).timeout
		current_pull_speed += 250 * delta
		
		var direction = (target_player.global_position - global_position).normalized()
		global_position += direction * current_pull_speed * delta
		
		var target_angle = direction.angle() + PI/2
		
		rotation += sin(Time.get_ticks_msec() * 0.01) * 0.05 
		rotation = lerp_angle(rotation, target_angle, 10.0 * delta)

func start_magnetic_pull(player):
	target_player = player
