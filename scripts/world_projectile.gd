extends Area2D

const PROJECTILE_TYPE_ENTITY = 0
const PROJECTILE_TYPE_ARROW = 1

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

#var sprite = null
#var collision = null
var player = null

var projectile = null

var is_projectile_from_player: bool = true

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
	projectile = DataManager.get_projectile(projectile_id)

	if projectile == null:
		print("Error: ID ", projectile_id, " doesnt exist in database!")
		return
	
	sprite = get_node("AnimatedSprite2D")
	collision = get_node("CollisionShape2D")
	
	var anim_path = "res://sprite_frames/projectiles/" + projectile_id + ".tres"
	if FileAccess.file_exists(anim_path):
		var new_frames = load(anim_path)
		sprite.sprite_frames = new_frames
		sprite.play("spawn")
	else:
		print("Animation was not found")
	
	global_position = pos

	projectile_stats = DataManager.get_projectile_stats(projectile_id)

	weapon_stats = used_weapon_stats

	if projectile_stats.get("projectile_type") == PROJECTILE_TYPE_ENTITY:
		is_projectile_from_player = false
		
	collision.shape = collision.shape.duplicate()
	collision.shape.size = Vector2(projectile_stats.get("hitbox_x", 16),
	 							   projectile_stats.get("hitbox_y", 16))
	direction = dir
	move_speed = projectile_stats.get("move_speed", 100.0)
	
	rotation = direction.angle()
	
	if projectile_stats.get("projectile_type") == PROJECTILE_TYPE_ARROW:
		rotation_degrees -= 90

func move(delta):
	if direction:
		global_position += direction * move_speed * delta

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	var attackable = area.get_parent()
	
	if attackable.has_method("take_hit") and is_projectile_from_player:
		var damage_to_deal: int
		var knockback: float
		
		if weapon_stats != {} and projectile_stats != {}:
			damage_to_deal = (projectile_stats.get("damage", 0) + weapon_stats.get("damage", 0)) / 2
			knockback = weapon_stats.get("knockback", 0)
			
			attackable.take_hit(damage_to_deal, knockback, global_position)
			queue_free()
	#elif not attackable.has_method("take_hit"):
		#MiningManager.spawn_hit_effect(MiningManager.current_tilemap.local_to_map(global_position))
		#queue_free()

func _on_body_entered(body) -> void:
	#player
	if body.has_method("take_hit") and not is_projectile_from_player:
		var damage_to_deal: int
		#var knockback: float
		if projectile_stats != {}:
			
			damage_to_deal = (projectile_stats.get("damage", 0))
			#knockback = weapon_stats.get("knockback", 0.0)
			body.take_hit(damage_to_deal)
			
	#elif not body.has_method("take_hit"):
		#MiningManager.spawn_hit_effect(MiningManager.current_tilemap.local_to_map(global_position))
		#queue_free()

func play_anim(anim_name: String, sprite_node):
	if has_node("AnimationPlayer"):
		var animation_player = $AnimationPlayer
		if animation_player.has_animation(anim_name) and animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
			
	elif has_node("AnimatedSprite2D"):
		if sprite_node.sprite_frames.has_animation(anim_name):
			sprite_node.play(anim_name)
