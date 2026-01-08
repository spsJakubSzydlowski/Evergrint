extends Area2D

var sprite = null
var collision = null
var player = null

var projectile = null

var projectile_stats = null
var weapon_stats = null

var direction: Vector2
var move_speed: float

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(delta: float) -> void:
	if projectile != null:
		move(delta)

func initialize(projectile_id: String, pos: Vector2, used_weapon_stats, dir: Vector2):
	projectile = DataManager.get_item(projectile_id)
	
	if projectile == null:
		print("Error: ID ", projectile_id, " doesnt exist in database!")
		return
		
	sprite = get_node("Sprite2D")
	collision = get_node("CollisionShape2D")

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
	
	global_position = pos

	projectile_stats = DataManager.get_projectile_stats(projectile_id)
	weapon_stats = used_weapon_stats
	
	collision.shape.size = Vector2(projectile_stats.get("hitbox_x", 16), projectile_stats.get("hitbox_y", 16))
	direction = dir
	move_speed = projectile_stats.get("move_speed", 100.0)
	
	rotation = direction.angle()

func move(delta):
	if direction:
		global_position += direction * move_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var attackable = area.get_parent()
	
	if attackable.has_method("take_hit") and not attackable.is_in_group("Player"):
		var damage_to_deal: int
		var knockback: float
		
		if weapon_stats != {} and projectile_stats != {}:
			damage_to_deal = (projectile_stats.get("damage", 0) + weapon_stats.get("damage", 0)) / 2
			knockback = weapon_stats.get("knockback", 0)
			
			attackable.take_hit(damage_to_deal, knockback, global_position)
			queue_free()
