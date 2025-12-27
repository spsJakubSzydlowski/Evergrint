extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

var entity = ""

var current_hp: int

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
	
func _on_body_entered(body) -> void:
	if body.is_in_group("Player"):
		deal_damage(body)
		
func take_hit(amount: int):
	current_hp -= amount
	print("Entity", entity.id, " has: ", current_hp, " HP")
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color.RED, 0.1)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		die()

func die():
	print("Entity", entity.id, " has died")
	queue_free()

func deal_damage(body):
	if body.has_method("take_damage"):
		var dmg = entity.get("damage", 0)
		body.take_damage(dmg)
		print("Entity", entity.id, " gave damage to player: ", dmg)
		
