extends CharacterBody2D

const FACTION_HOSTILE = 0
const FACTION_PASSIVE = 1

@onready var sprite: Sprite2D = $Sprite2D

var entity = ""

var player = null

var current_hp: int
var is_dead = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")

func _physics_process(_delta: float) -> void:
	if entity.get("faction") == FACTION_HOSTILE:
		if player and not is_dead:
			var direction = (player.global_position - global_position).normalized()
			
			var move_speed = entity.get("move_speed")
			velocity = direction * move_speed
			
			move_and_slide()
			
			if direction.x != 0:
				sprite.flip_h = direction.x < 0

func initialize(entity_id: String):
	entity = DataManager.get_entity(entity_id)
	
	if entity == null:
		print("Error: ID ", entity_id, " doesnt exist in database!")
		return
	
	name = entity.id
	
	if entity.has("tile"):
		var raw_path = entity.tile.file
		var clean_path = "res://" + raw_path.replace("../", "")
		
		var tex = load(clean_path)
		if tex:
			sprite.texture = tex
			sprite.region_enabled = true
			
			var ts = entity.tile_size
			sprite.region_rect = Rect2(entity.tile.x * ts, entity.tile.y * ts, ts, ts)
	
	current_hp = entity.get("max_hp", 1)

func _on_world_entity_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		deal_damage(body)
		

func take_hit(amount: int):
	if is_dead: return
	
	current_hp -= amount
	print("Entity", entity.id, " has: ", current_hp, " HP")
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.RED, 0.1)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		die()

func die():
	is_dead = true
	print("Entity", entity.id, " has died")
	queue_free()

func deal_damage(body):
	if body.has_method("take_hit"):
		var dmg = entity.get("damage", 0)
		body.take_hit(dmg)
		print("Entity", entity.id, " gave damage to player: ", dmg)

func drop_loot(loot_table_id):
	pass
