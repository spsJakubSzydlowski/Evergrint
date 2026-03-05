extends CanvasModulate

@onready var anim: AnimationPlayer = $AnimationPlayer

func _process(_delta: float) -> void:
	anim.play("day_night")
	anim.seek(TimeManager.time_percent, true)
	
	anim.speed_scale = 0

func change_part_of_day(part: String):
	match part:
		"dawn": TimeManager.current_part_of_day = Enums.PartsOfDay.DAWN
		"day": TimeManager.current_part_of_day = Enums.PartsOfDay.DAY
		"dusk": TimeManager.current_part_of_day = Enums.PartsOfDay.DUSK
		"night": TimeManager.current_part_of_day = Enums.PartsOfDay.NIGHT
