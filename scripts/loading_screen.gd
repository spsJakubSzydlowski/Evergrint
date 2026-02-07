extends CanvasLayer

@onready var loading_text: RichTextLabel = $ColorRect/MarginContainer/RichTextLabel
@onready var color_rect: ColorRect = $ColorRect

var target_scene_path: String
var progress = []

var min_loading_time = 2
var elapsed_time = 0.0
var loading_finished = false
var scene_instantiated = false

var dots_count = 0

func _ready() -> void:
	ResourceLoader.load_threaded_request(target_scene_path)
	loading_text.text = "Loading"
	elapsed_time = 0.0

func _process(delta: float) -> void:
	elapsed_time += delta
	
	var status = ResourceLoader.load_threaded_get_status(target_scene_path, progress)
	
	if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		pass
	
	if status == ResourceLoader.THREAD_LOAD_LOADED and not loading_finished:
		scene_instantiated = true
		prepare_scene_under_loading()
	
	if scene_instantiated and elapsed_time >= min_loading_time and not loading_finished:
		loading_finished = true
		start_transition()
	
	if status == ResourceLoader.THREAD_LOAD_FAILED:
		print("Error occured while changing scenes")

func prepare_scene_under_loading():
	var packed_scene = ResourceLoader.load_threaded_get(target_scene_path)
	var new_scene_instance = packed_scene.instantiate()
	
	var current_scene = get_tree().current_scene
	get_tree().root.add_child(new_scene_instance)
	get_tree().current_scene = new_scene_instance
	current_scene.queue_free()

func start_transition():
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _on_timer_timeout() -> void:
	dots_count = (dots_count + 1) % 4
	var dots = ""
	
	for i in range(dots_count):
		dots += "."
	
	loading_text.text = "Loading" + dots
