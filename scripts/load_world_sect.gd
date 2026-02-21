extends Control

@onready var play_button: Button = $HBoxContainer/play_button
@onready var return_button: Button = $HBoxContainer/return_button

@onready var worlds_list: VBoxContainer = $MarginContainer/VBoxContainer/ScrollContainer/worlds_list
var world_container = preload("res://scenes/UI/world_container.tscn")

var selected_world_name = ""
enum Actions {NONE, CREATE, LOAD}
var current_action = Actions.NONE

var all_worlds

func play_click():
	AudioManager.play_sfx("menu_click")

func _ready() -> void:
	Signals.select_world.connect(_select_world_signal)
	all_worlds = SaveManager.get_all_worlds()

func _select_world_signal(world_name):
	if world_name != "":
		selected_world_name = world_name
		play_button.disabled = false
	else:
		selected_world_name = world_name
		play_button.disabled = true

func _on_play_button_pressed() -> void:
	play_click()
	Signals.play_world.emit(selected_world_name)

func _on_return_button_pressed() -> void:
	play_click()
	Signals.switch_to_section.emit("menu")

func _on_visibility_changed() -> void:
	if not visible: return
	
	selected_world_name = ""
	play_button.disabled = true
	
	for child in worlds_list.get_children():
		worlds_list.remove_child(child)
		child.queue_free()
	
	for world in all_worlds:
		var new_world = world_container.instantiate()
		
		new_world.find_child("world_name_label").text = world.get("world_name", "???")
		new_world.find_child("last_played_label").text = world.get("last_played", "null")
		new_world.world_name = world.get("world_name", "???")
		
		worlds_list.add_child(new_world)
