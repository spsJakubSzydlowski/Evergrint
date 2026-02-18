extends CanvasLayer

@onready var sections = {
	"menu": $menu_sect,
	"create": $create_world_sect,
	"worlds": $load_world_sect
}

enum Actions {NONE, CREATE, LOAD}
var current_action = Actions.NONE
var selected_difficulty = Global.Difficulty.EASY
var selected_world_name = ""

#region MENU_SECT Variables
@onready var new_game_button: Button = $menu_sect/MarginContainer2/VBoxContainer/new_game_button
@onready var load_game_button: Button = $menu_sect/MarginContainer2/VBoxContainer/load_game_button
#endregion

#region CREATE_WORLD_SECT Variables
@onready var name_edit: LineEdit = $create_world_sect/MarginContainer/VBoxContainer/name_edit
@onready var seed_edit: LineEdit = $create_world_sect/MarginContainer/VBoxContainer/seed_edit
@onready var difficulty_button: Button = $create_world_sect/MarginContainer/VBoxContainer/difficulty_button
@onready var return_button: Button = $create_world_sect/HBoxContainer/return_button
@onready var create_button: Button = $create_world_sect/HBoxContainer/create_button
#endregion

#region LOAD_WORLD_SECT Variables
@onready var worlds_list: VBoxContainer = $load_world_sect/MarginContainer/VBoxContainer/ScrollContainer/worlds_list
@onready var play_button: Button = $load_world_sect/HBoxContainer/play_button
#endregion

var world_container = preload("res://scenes/UI/world_container.tscn")
var all_worlds

func _ready() -> void:
	all_worlds = SaveManager.get_all_worlds()
	Signals.play_world.connect(_play_world_signal)
	Signals.select_world.connect(_select_world_signal)
	switch_to_section("menu")

func switch_to_section(target_section: String):
	for section_name in sections:
		sections[section_name].visible = (section_name == target_section)
	
	if target_section == "menu":
		if all_worlds.is_empty():
			load_game_button.disabled = true
		else:
			load_game_button.disabled = false
	
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

func setup_and_start():
	play_click()
	
	var world_name = get_safe_world_name(name_edit.text)
	var world_seed = get_seed_int(seed_edit.text)
	
	Global.world_name = world_name
	Global.world_seed = world_seed
	Global.current_difficulty = selected_difficulty
	
	if selected_difficulty == Global.Difficulty.EASY:
		Global.set_difficulty_mult("easy")
	elif selected_difficulty == Global.Difficulty.HARD:
		Global.set_difficulty_mult("hard")
	
	Signals.play_world.emit(Global.world_name)

func start_game(world_name: String):
	if current_action == Actions.CREATE:
		if not SaveManager.create_world(world_name, Global.world_seed):
			print("This world already exist!")
			return
			
	elif current_action == Actions.LOAD:
		if not SaveManager.load_world(world_name):
			print("This world doesnt exist!")
			return
	
	Global.transition_to("surface")
	return

func play_click():
	AudioManager.play_sfx("menu_click")

#region SIGNALS

func _select_world_signal(world_name):
	if world_name != "":
		selected_world_name = world_name
		play_button.disabled = false
	else:
		selected_world_name = world_name
		play_button.disabled = true

func _play_world_signal(world_name):
	start_game(world_name)

func _on_new_game_button_mouse_entered() -> void:
	new_game_button.set("theme_override_colors/font_hover_color", Color(0, 0, 0))
	new_game_button.set("theme_override_constants/outline_size", 0)

func _on_new_game_button_mouse_exited() -> void:
	new_game_button.set("theme_override_colors/font_color", Color(1, 1, 1))
	new_game_button.set("theme_override_constants/outline_size", 4)

func _on_new_game_button_pressed() -> void:
	play_click()
	switch_to_section("create")
	current_action = Actions.CREATE

func _on_button_mouse_entered(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 0)
		
func _on_button_mouse_exited(button):
	if get_node(button).disabled == false:
		get_node(button).set("theme_override_constants/outline_size", 4)

func _on_load_game_button_pressed() -> void:
	play_click()
	switch_to_section("worlds")
	current_action = Actions.LOAD
	
	for child in worlds_list.get_children():
		worlds_list.remove_child(child)
		child.queue_free()
	
	for world in all_worlds:
		var new_world = world_container.instantiate()
		
		new_world.find_child("world_name").text = world
		new_world.world_name = world
		
		worlds_list.add_child(new_world)

func _on_name_edit_text_changed(new_text: String) -> void:
	create_button.disabled = false

	for world_name in all_worlds:
		if new_text == world_name or new_text == "":
			create_button.disabled = true

func _on_seed_edit_text_changed(_new_text: String) -> void:
	pass # Replace with function body.

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

func _on_play_button_pressed() -> void:
	play_click()
	Signals.play_world.emit(selected_world_name)

func _on_return_button_pressed() -> void:
	play_click()
	switch_to_section("menu")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

#endregion
