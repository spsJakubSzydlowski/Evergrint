extends Control

@onready var compas_label: RichTextLabel = $HBoxContainer/compas_label
@onready var time_label: RichTextLabel = $HBoxContainer/time_label

func _ready() -> void:
	visible = false

func get_compas_text(relative_pos):
	if relative_pos == Vector2i.ZERO: return "0N 0E"
	
	var ns = str(abs(relative_pos.y)) + ("N" if relative_pos.y < 0 else "S")
	var we = str(abs(relative_pos.x)) + ("W" if relative_pos.x < 0 else "E")
	
	return "%s %s" % [ns, we]

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("toggle_info"):
		visible = not visible

func _process(_delta: float) -> void:
	time_label.text = "%02d:%02d" % [TimeManager.hours, TimeManager.minutes]

func _on_update_timer_timeout() -> void:
	if Global.current_tilemap:
		var relative_pos = Vector2i(Global.get_player_tilemap_position(Global.current_tilemap)) - Global.center_world_pos
		
		compas_label.text = get_compas_text(relative_pos)
