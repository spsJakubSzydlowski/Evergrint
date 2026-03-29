extends Button

@onready var setting_label: Label = %setting_label
@onready var button_text: Label = %button_text

@onready var anim: AnimationPlayer = $AnimationPlayer

var setting_id
var setting_name: String
var button_index: int

func _ready() -> void:
	
	setting_label.text = setting_name
	
	if button_index < 10:
		button_text.text = get_mouse_button_text(button_index)
	else:
		button_text.text = OS.get_keycode_string(button_index)
		
	if button_text.text == "":
		button_text.text = "<Unbound>"

func play_click():
	AudioManager.play_sfx("menu_click")

func _on_pressed() -> void:
	play_click()
	var event = await wait_for_input_event()
	
	if button_text.text == "":
		button_text.text = "<Unbound>"
	
	if event is InputEventMouseButton:
		button_text.text = get_mouse_button_text(event.button_index)
		Controls.controls[setting_id] = event.button_index
		
	elif event is InputEventKey:
		var code = event.keycode if event.keycode != 0 else event.physical_keycode
		button_text.text = OS.get_keycode_string(code)
		Controls.controls[setting_id] = code

func wait_for_input_event():
	get_viewport().gui_release_focus()
	
	anim.play("pulse")
	disabled = true
	
	await get_tree().create_timer(0.1).timeout
	
	while true:
		var event = await get_tree().root.window_input
		if event is InputEventKey or event is InputEventMouseButton:
			if event.is_pressed() and not event.is_echo():
				disabled = false
				anim.play("RESET")
				
				get_viewport().set_input_as_handled()
				
				return event

func get_mouse_button_text(index: int) -> String:
	match index:
		MOUSE_BUTTON_LEFT: return "Left Mouse Button"
		MOUSE_BUTTON_RIGHT: return "Right Mouse Button"
		MOUSE_BUTTON_MIDDLE: return "Middle Mouse Button"
		MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
		MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
		_: return "Mouse Button " + str(index)
