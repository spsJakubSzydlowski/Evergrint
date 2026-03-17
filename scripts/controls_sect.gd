extends Control

@onready var control_grid: GridContainer = $control_grid
var row_scene = preload("res://scenes/UI/change_control_row.tscn")

var controls = [
	"Move Up",
	"Move Down",
	"Move Left",
	"Move Right"
]


func _on_visibility_changed() -> void:
	for child in control_grid.get_children():
		child.queue_free()
	
	for control in controls:
		var row = row_scene.instantiate()
		row.setting_name = control
		control_grid.add_child(row)
