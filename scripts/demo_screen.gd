extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var itch: TextureButton = $ColorRect/links/HBoxContainer/itch
@onready var github: TextureButton = $ColorRect/links/HBoxContainer/github

func _ready() -> void:
	itch.pivot_offset = itch.size / 2
	github.pivot_offset = github.size / 2
	
	Signals.boss_died.connect(_on_boss_died)
	color_rect.modulate.a = 0.0
	visible = false

func _on_boss_died(boss_id):
	if boss_id == "mole_boss" and Global.mole_boss_kills == 1:
		var tween = create_tween()
		tween.tween_interval(1.0)
		tween.tween_callback(start_transition)

func start_transition():
	visible = true
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, 0.25)

func _on_button_pressed() -> void:
	visible = false


func _on_itch_pressed() -> void:
	OS.shell_open("https://kubki.itch.io/evergrint")

func _on_github_pressed() -> void:
	OS.shell_open("https://github.com/spsJakubSzydlowski/Evergrint")


func _on_itch_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(itch, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_QUAD)

func _on_itch_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(itch, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD)

func _on_github_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(github, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_QUAD)

func _on_github_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(github, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD)
