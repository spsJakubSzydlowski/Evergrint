extends Area2D

var sprite = null

var projectile = null

var direction: Vector2
var move_speed: float

func _physics_process(delta: float) -> void:
	if projectile != null:
		move(delta)

func initialize(projectile_id: String, _pos: Vector2, _weapon_stats, dir: Vector2):
	projectile = DataManager.get_item(projectile_id)
	
	if projectile == null:
		print("Error: ID ", projectile_id, " doesnt exist in database!")
		return
		
	sprite = get_node("Sprite2D")
	
	if projectile.has("tile"):
		var raw_path = projectile.tile.file
		var clean_path = "res://" + raw_path.replace("../", "")
		
		var tex = load(clean_path)
		if tex:
			sprite.texture = tex
			sprite.region_enabled = true
			
			var ts_base = Vector2i(projectile.get("tile_size"), projectile.get("tile_size"))
			
			var pos_x = projectile.tile.x * ts_base.x
			var pos_y = projectile.tile.y * ts_base.y
			
			var region_w = projectile.tile_width * ts_base.x
			var region_h = projectile.tile_height * ts_base.y
			
			sprite.region_rect = Rect2(pos_x, pos_y, region_w, region_h)
	
	var projectile_stats = DataManager.get_projectile_stats(projectile_id)
	
	direction = dir
	move_speed = projectile_stats.get("move_speed", 100.0)
	
	rotation = direction.angle()
	
func move(delta):
	if direction:
		global_position += direction * move_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
