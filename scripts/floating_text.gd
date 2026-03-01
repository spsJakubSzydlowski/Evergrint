extends Node2D

func setup(text_value: String, color: Color = Color.WHITE):
	%Label.text = text_value
	%Label.modulate = color
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	%anim.play("pop_up")

func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	queue_free()
