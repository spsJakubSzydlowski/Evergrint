extends Button

@onready var setting_label: Label = %setting_label
@onready var button_text: Label = %button_text

@onready var anim: AnimationPlayer = $AnimationPlayer

var setting_name: String

func _ready() -> void:
	
	setting_label.text = setting_name

func _on_pressed() -> void:
	var input_name = await wait_for_input()
	button_text.text = input_name

func wait_for_input():
	anim.play("pulse")
	while true:
		var event = await get_tree().root.window_input
		if event is InputEventKey or event is InputEventMouseButton:
			if event.is_pressed():
				anim.play("RESET")
				if event is InputEventKey:
					return str(OS.get_keycode_string(event.keycode))
				if event is InputEventMouseButton:
					return get_mouse_button_text(event.button_index)
					
func get_mouse_button_text(index: int) -> String:
	match index:
		MOUSE_BUTTON_LEFT: return "Left Mouse Button"
		MOUSE_BUTTON_RIGHT: return "Right Mouse Button"
		MOUSE_BUTTON_MIDDLE: return "Middle Mouse Button"
		MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
		_: return "Mouse Button " + str(index)
