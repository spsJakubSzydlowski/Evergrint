extends CanvasLayer

@onready var respawn_label: Label = $VBoxContainer/respawn_label
@onready var respawn_timer: Timer = $respawn_timer
@onready var die_label: Label = $VBoxContainer/DieLabel

func _ready() -> void:
	visible = false
	die_label.visible = false
	Signals.player_died.connect(on_player_died)
	
func on_player_died():
	visible = true
	die_label.visible = true
	respawn_timer.start()
	respawn_label.text = str(respawn_timer.time_left)

func time_left_to_live():
	return respawn_timer.time_left

func respawn_player():
	var player = get_tree().get_first_node_in_group("Player")
	if player:
		player.respawn()
	
	respawn_timer.stop()
	visible = false
	die_label.visible = false

func _process(_delta: float) -> void:
	respawn_label.text = "%2d" % (time_left_to_live() + 1)

func _on_respawn_timer_timeout() -> void:
	respawn_player()
