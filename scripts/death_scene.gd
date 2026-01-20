extends CanvasLayer

@onready var die_label: Label = $DieLabel

func _ready() -> void:
	visible = false
	die_label.visible = false
	Signals.player_died.connect(on_player_died)
	
func on_player_died():
	visible = true
	die_label.visible = true

	var tween = create_tween()
	tween.tween_interval(5)
	tween.tween_callback(respawn_player)

func respawn_player():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.respawn()

	visible = false
	die_label.visible = false
