extends Node

var world_seed: int = 0
var player_pos = null
var first_time_generation = true
var world_changes = {}

func _ready():
	randomize()
	world_seed = randi()
	print("World seed is: ", world_seed)

var world_scenes = {
	"surface": "res://scenes/main.tscn",
	"underground": "res://scenes/underground.tscn"
}

var current_layer = "surface"

func transition_to(target_layer: String):
	current_layer = target_layer
	get_tree().change_scene_to_file(world_scenes[target_layer])
