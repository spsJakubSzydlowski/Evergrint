extends Area2D

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D

var item = ""

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
			
			var ts = item.tile_size
			sprite.region_rect = Rect2(item.tile.x * ts, item.tile.y * ts, ts, ts)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		collect_item()

func collect_item():
	Inventory.add_item(item.id)
	queue_free()
