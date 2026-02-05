extends Node

func projectile_burst(projectile_id, source, count: int):
	var tween = source.create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(func():
		for i in range(count):
			var angle = i * (PI * 2 / count)
			var offset = randf_range(0, 360)
			
			var direction = Vector2.RIGHT.rotated(angle + offset)
			
			DataManager.spawn_projectile(projectile_id, source.global_position, {}, direction)
		
			AudioManager.play_sfx(projectile_id)
	
	)
	
func spawn_at_player(source, player):
	source.is_acting = true
	source.can_be_hit = false
	
	source.velocity = Vector2.ZERO
	var target_pos = player.global_position
	
	var tween = source.create_tween()
	
	if source.has_method("play_anim"):
		source.play_anim("dig_down", source.sprite)
	
	tween.tween_interval(1.0)
	
	tween.tween_callback(func():
		
		source.set_deferred("global_position", target_pos)
	)

	tween.tween_callback(func(): 
		if source.has_method("play_anim"):
			source.play_anim("spawn", source.sprite)
		source.is_acting = false
		source.can_be_hit = true)

func wait(source, interval):
	source.is_acting = true
	source.velocity = Vector2.ZERO
	
	if source.has_method("play_anim"):
		source.play_anim("idle", source.sprite)
		
	var tween = source.create_tween()
	
	tween.tween_interval(interval)
	
	tween.tween_callback(func():
		source.is_acting = false
	)
