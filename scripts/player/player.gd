extends CharacterBody2D

var SPEED : float = 100.0
@onready var sprite: Sprite2D = $Sprite2D

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
	
	if direction.x > 0:
		sprite.flip_h = false
	move_and_slide()
