extends TextureProgressBar

@onready var health_label: Label = $health_label

func _ready() -> void:
	Signals.player_health_changed.connect(update_health_bar)
	health_label.visible = false

func _process(_delta: float) -> void:
	var mouse_pos = get_viewport().get_mouse_position()
	if health_label.visible:
		health_label.global_position = mouse_pos + Vector2(4, 4)

func _on_health_bar_mouse_entered() -> void:
	health_label.visible = true

func _on_health_bar_mouse_exited() -> void:
	health_label.visible = false

func update_health_bar(current_hp, max_hp) -> void:
	max_value = max_hp
	value = current_hp
	
func _on_health_bar_value_changed(hp_value: float) -> void:
	health_label.text = str(int(hp_value)) + "/" + str(int(max_value))
