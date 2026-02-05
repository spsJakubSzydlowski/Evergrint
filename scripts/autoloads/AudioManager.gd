extends Node

func play_entity_sfx(entity_id: String, action: String, pos: Vector2):
	var final_id = entity_id + "_" + action
	play_sfx(final_id, pos)
	
func play_sfx(sound_id: String, pos: Vector2 = Vector2.ZERO):
	var data = DataManager.get_audio(sound_id)
	if not data:
		return
	var raw_path = data.file
	var clean_path = "res://" + raw_path.replace("../", "")
	var stream = load(clean_path)
	
	if pos == Vector2.ZERO:
		_spawn_player(stream, data)
	else:
		_spawn_spatial_player(stream, data, pos)

func _spawn_player(stream, data):
	var player = AudioStreamPlayer.new()
	add_child(player)
	_setup_player(player, stream, data)

func _spawn_spatial_player(stream, data, pos):
	var p = AudioStreamPlayer2D.new()
	add_child(p)
	p.position = pos
	p.max_distance = data.get("max_dist", 600)
	_setup_player(p, stream, data)

func _setup_player(player, stream, data):
	player.stream = stream
	player.volume_db = data.get("volume", 0.0)
	player.pitch_scale = randf_range(data.get("pitch_min", 0.9), data.get("pitch_max", 1.1))
	player.play()
	
	player.finished.connect(player.queue_free)
