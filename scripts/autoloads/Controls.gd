extends Node

func _ready() -> void:
	Signals.change_controls.connect(_on_controls_change)
	setup_controls()

var default_controls = {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"attack": MOUSE_BUTTON_LEFT,
	"interact": MOUSE_BUTTON_RIGHT,
	"dash": KEY_SPACE,
	"heal": KEY_H,
	"pause": KEY_ESCAPE,
	"toggle_inv": KEY_E,
	"toggle_info": KEY_C,
}

var controls = {
	"move_up": KEY_W,
	"move_down": KEY_S,
	"move_left": KEY_A,
	"move_right": KEY_D,
	"attack": MOUSE_BUTTON_LEFT,
	"interact": MOUSE_BUTTON_RIGHT,
	"dash": KEY_SPACE,
	"heal": KEY_H,
	"pause": KEY_ESCAPE,
	"toggle_inv": KEY_E,
	"toggle_info": KEY_C,
}

var control_names = [
	"Move Up",
	"Move Down",
	"Move Left",
	"Move Right",
	"Attack",
	"Interact",
	"Dash",
	"Heal",
	"Pause",
	"Toggle inventory",
	"Toggle information",
]

func setup_controls():
	for action_name in controls:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		
		InputMap.action_erase_events(action_name)
		
		var input_val = controls[action_name]
		var new_event
		
		if input_val < 10:
			new_event = InputEventMouseButton.new()
			new_event.button_index = input_val
		else:
			new_event = InputEventKey.new()
			new_event.physical_keycode = input_val
			
		InputMap.action_add_event(action_name, new_event)

func _on_controls_change():
	setup_controls()
