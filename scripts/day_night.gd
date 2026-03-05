extends CanvasModulate


@onready var anim: AnimationPlayer = $AnimationPlayer
@export var day_duration = 30.0

func _ready() -> void:
	anim.speed_scale = 1.0 / day_duration
	anim.play("day_night")

func change_part_of_day(part: String):
	match part:
		"dawn": Global.current_part_of_day = Enums.PartsOfDay.DAWN
		"day": Global.current_part_of_day = Enums.PartsOfDay.DAY
		"dusk": Global.current_part_of_day = Enums.PartsOfDay.DUSK
		"night": Global.current_part_of_day = Enums.PartsOfDay.NIGHT
