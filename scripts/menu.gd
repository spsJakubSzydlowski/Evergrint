extends CanvasLayer

@onready var sections = {
	"menu": $menu_sect,
	"create": $create_world_sect,
	"worlds": $load_world_sect,
	"options": $options_sect
}

enum Actions {NONE, CREATE, LOAD}
var current_action = Actions.NONE
var selected_difficulty = Global.Difficulty.EASY

var all_worlds

func _ready() -> void:
	Global.world_name = ""
	Global.first_time_generation = false
	all_worlds = SaveManager.get_all_worlds()
	Signals.play_world.connect(_play_world_signal)
	Signals.switch_to_section.connect(_on_switch_to_section)
	Signals.switch_to_section.emit("menu")
	
	for child in get_tree().get_nodes_in_group("menu_buttons"):
		if child is Button:
			child.mouse_entered.connect(_on_any_button_mouse_entered.bind(child.name))
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		Signals.switch_to_section.emit("menu")

func _on_switch_to_section(target_section: String):
	for section_name in sections:
		sections[section_name].visible = (section_name == target_section)

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

#region SIGNALS

func _on_any_button_mouse_entered(_button):
	AudioManager.play_sfx("button_hover")

func _play_world_signal(world_name):
	start_game(world_name)

#endregion
