extends Node

var day_duration = 1200.0
var time_percent = 0.0

var hours: int = 0
var minutes: int = 0

var current_part_of_day = Enums.PartsOfDay.DAY

func _process(delta: float) -> void:
	time_percent += delta / day_duration
	
	if time_percent >= 1.0:
		time_percent = fmod(time_percent, 1.0)
	
	var raw_hour = (time_percent * 24) + 6.0
	var game_hour = fmod(raw_hour, 24.0)
	
	hours = int(game_hour)
	minutes = int((game_hour - hours) * 60)
