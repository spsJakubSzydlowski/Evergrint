extends Control


func _ready() -> void:
	Signals.autosaving.connect(_on_autosave)

func _on_visibility_changed() -> void:
	if visible:
		%anim.play("show")
		
func _on_autosave():
	visible = true

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	visible = false
