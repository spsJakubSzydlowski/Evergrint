extends Control

@onready var name_edit: LineEdit = $MarginContainer/VBoxContainer/name_edit
@onready var seed_edit: LineEdit = $MarginContainer/VBoxContainer/seed_edit
@onready var return_button: Button = $HBoxContainer/return_button
@onready var create_button: Button = $HBoxContainer/create_button
@onready var difficulty_button: Button = $MarginContainer/VBoxContainer/MarginContainer/difficulty_button

var all_worlds

var selected_difficulty = Global.Difficulty.EASY
var world_seed

func _ready() -> void:
	all_worlds = SaveManager.get_all_worlds()

func play_click():
	AudioManager.play_sfx("menu_click")

func get_safe_world_name(input_name: String):
	var safe_name = input_name.strip_edges()
	
	safe_name = safe_name.replace(" ", "").replace("\t", "")
	
	safe_name = safe_name.validate_filename()
	
	if safe_name.length() > 32:
		safe_name = safe_name.substr(0, 32)
		
	var regex = RegEx.new()
	regex.compile("_+")
	safe_name = regex.sub(safe_name, "_", true)
	
	if safe_name == "" or safe_name == "_":
		safe_name = "Unnamed_World" + str(randi())
	
	return safe_name

func get_seed_int(input_seed: String):
	var rng = RandomNumberGenerator.new()
	rng.seed = input_seed.hash()
	
	var int_seed = rng.seed
	
	return int_seed

func _on_name_edit_text_changed(new_text: String) -> void:
	create_button.disabled = false

	for world in all_worlds:
		var world_name = world.get("world_name")
		if new_text == world_name or new_text == "":
			create_button.disabled = true

func _on_difficulty_button_pressed() -> void:
	play_click()
	if selected_difficulty == Global.Difficulty.EASY:
		selected_difficulty = Global.Difficulty.HARD
		difficulty_button.text = "Difficulty: Hard"
	else:
		selected_difficulty = Global.Difficulty.EASY
		difficulty_button.text = "Difficulty: Easy"

func _on_create_button_pressed() -> void:
	play_click()
	setup_and_start()

func _on_return_button_pressed() -> void:
	play_click()
	Signals.switch_to_section.emit("menu")

func setup_and_start():
	play_click()
	
	var world_name = get_safe_world_name(name_edit.text)
	if seed_edit.text != "":
		world_seed = get_seed_int(seed_edit.text)
	else:
		world_seed = randi()
	
	Global.world_name = world_name
	Global.world_seed = world_seed
	Global.current_difficulty = selected_difficulty
	
	if selected_difficulty == Global.Difficulty.EASY:
		Global.set_difficulty_mult("easy")
	elif selected_difficulty == Global.Difficulty.HARD:
		Global.set_difficulty_mult("hard")
	
	Signals.play_world.emit(Global.world_name)

func _on_name_edit_visibility_changed() -> void:
	if name_edit:
		name_edit.text = ""

		if name_edit.text == "":
			create_button.disabled = true

func _on_seed_edit_visibility_changed() -> void:
	if seed_edit:
		seed_edit.text = ""
