extends CanvasLayer

@onready var sections = {
	"menu": $menu_sect,
	"difficulty": $difficulties_sect,
	"name": $world_name_sect,
	"worlds": $load_world_sect
}
@onready var name_edit: LineEdit = $world_name_sect/HBoxContainer/name_edit
@onready var name_enter: Button = $world_name_sect/HBoxContainer/name_enter
@onready var worlds_list: VBoxContainer = $load_world_sect/VBoxContainer/ScrollContainer/worlds_list

var world_container = preload("res://scenes/UI/world_container.tscn")

var action = "" #create/load

func _ready() -> void:
	Signals.play_world.connect(_play_world_signal)
	switch_to_section("menu")

func switch_to_section(target_section: String):
	for section_name in sections:
		sections[section_name].visible = (section_name == target_section)

func _on_name_enter_pressed() -> void:
	print(get_safe_world_name(name_edit.text))
	var world_name = get_safe_world_name(name_edit.text)
	
	Global.world_name = world_name
	
	if action == "create":
		switch_to_section("difficulty")
	else:
		Signals.play_world.emit(world_name)

func _on_name_edit_text_changed(new_text: String) -> void:
	var worlds = SaveManager.get_all_worlds()
	name_enter.disabled = false

	for world_name in worlds:
		if new_text == world_name or new_text == "":
			name_enter.disabled = true

func get_safe_world_name(input_name: String):
	var safe_name = input_name.strip_edges()
	
	
	safe_name = safe_name.replace(" ", "").replace("\t", "")
	
	safe_name = safe_name.validate_filename()
	
	if safe_name == "" or safe_name == "_":
		safe_name = "Unnamed_World"
	
	if safe_name.length() > 32:
		safe_name = safe_name.substr(0, 32)
		
	var regex = RegEx.new()
	regex.compile("_+")
	safe_name = regex.sub(safe_name, "_", true)
	
	return safe_name

func _on_new_game_button_pressed() -> void:
	play_click()
	switch_to_section("name")
	action = "create"

func _on_load_game_button_pressed() -> void:
	play_click()
	switch_to_section("worlds")
	action = "load"
	
	for child in worlds_list.get_children():
		worlds_list.remove_child(child)
		child.queue_free()
	
	var all_worlds = SaveManager.get_all_worlds()
	for world in all_worlds:
		var new_world = world_container.instantiate()
		
		new_world.get_node("world_name").text = world
		new_world.world_name = world
		
		worlds_list.add_child(new_world)

func _on_easy_button_pressed() -> void:
	setup_and_start(Global.Difficulty.EASY, "easy")

func _on_hard_button_pressed() -> void:
	setup_and_start(Global.Difficulty.HARD, "hard")

func setup_and_start(difficulty_type, difficulty_name: String):
	play_click()
	Global.current_difficulty = difficulty_type
	Global.set_difficulty_mult(difficulty_name)
	Signals.play_world.emit(Global.world_name)

func _play_world_signal(world_name):
	start_game(world_name)

func start_game(world_name: String):
	if action == "create":
		if not SaveManager.create_world(world_name):
			print("This world already exist!")
			return
			
	elif action == "load":
		if not SaveManager.load_world(world_name):
			print("This world doesnt exist!")
			return
	
	Global.transition_to("surface")
	return

func play_click():
	AudioManager.play_sfx("menu_click")
