extends CanvasLayer

@onready var sections = {
	"menu": $menu_sect,
	"difficulty": $difficulties_sect,
	"name": $world_name_sect
}
@onready var name_edit: LineEdit = $world_name_sect/HBoxContainer/name_edit
@onready var name_enter: Button = $world_name_sect/HBoxContainer/name_enter

var action = "" #create/load

func _ready() -> void:
	switch_to_section("menu")

func switch_to_section(target_section: String):
	for section_name in sections:
		sections[section_name].visible = (section_name == target_section)

func _on_name_enter_pressed() -> void:
	var world_name = name_edit.text.strip_edges()
	
	if world_name == "": return
	
	Global.world_name = world_name
	
	if action == "create":
		switch_to_section("difficulty")
	else:
		start_game(world_name)

func _on_name_edit_text_changed(new_text: String) -> void:
	if action == "load":
		name_enter.disabled = false
		return
	
	var worlds = SaveManager.get_all_worlds()
	name_enter.disabled = false

	for world_name in worlds:
		if new_text == world_name or new_text == "":
			name_enter.disabled = true
		
func _on_new_game_button_pressed() -> void:
	play_click()
	switch_to_section("name")
	action = "create"
	
func _on_load_game_button_pressed() -> void:
	play_click()
	switch_to_section("name")
	action = "load"

func _on_easy_button_pressed() -> void:
	setup_and_start(Global.Difficulty.EASY, "easy")

func _on_hard_button_pressed() -> void:
	setup_and_start(Global.Difficulty.HARD, "hard")

func setup_and_start(difficulty_type, difficulty_name: String):
	play_click()
	Global.current_difficulty = difficulty_type
	Global.set_difficulty_mult(difficulty_name)
	start_game(Global.world_name)

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
	
func play_click():
	AudioManager.play_sfx("menu_click")
