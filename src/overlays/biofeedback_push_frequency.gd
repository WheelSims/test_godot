extends Control


@onready var main: Node = get_tree().get_root().get_node("main")

var pos_init_slider
@export_category("Slider parameters")
@export var min_value = 0.4
@export var max_value = 2.5

@export var min_target_value = 1.0
@export var max_target_value = 2.0

var value = 0.6

@export_category("Nodes")
@export var node_min_value: Node
@export var node_max_value: Node
@export var node_min_target_value: Node
@export var node_max_target_value: Node
@export var node_value: Node
@export var node_slider_zone: Node
@export var node_slider: Node
@export var node_target_zone: Node
@export var node_green_zone: Node

func _ready():
	var timer = Timer.new()
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_update_loop)

func _update_loop():

	var data = main.get_node("python_bridge").receive_data()
	
	if data is Dictionary:
		if data["data"]["left"]["mean_push_frequency"]:
			value = data["data"]["left"]["mean_push_frequency"]

	node_min_value.text = str(min_value)
	node_max_value.text = str(max_value)
	node_value.text = str(snappedf(value, 0.1))

	node_slider.position.y = node_slider_zone.size.y - (value - min_value) * node_slider_zone.size.y / (max_value-min_value)
	node_slider.size.x = node_slider_zone.size.x
	
	node_target_zone.position.y = node_slider_zone.size.y - (min_target_value - min_value) * node_slider_zone.size.y / (max_value-min_value)
	node_green_zone.size.y = node_slider_zone.size.y * (max_target_value - min_target_value) / (max_value - min_value)

	node_min_target_value.text = str(min_target_value)
	node_max_target_value.text = str(max_target_value)
	
	node_max_target_value.position.y = node_green_zone.size.y

	# Should we quit
	if not Config.get_value("overlays.biofeedback_push_frequency.enabled"):
		queue_free()
		
	request_biofeedback()


func request_biofeedback():
	var arg = {
		"coordinates_left_wheel_center": Config.get_value("coordinates.left_wheel_center"),
		"coordinates_right_wheel_center": Config.get_value("coordinates.right_wheel_center"),
		"coordinates_left_hand": Config.get_value("coordinates.left_hand"),
		"coordinates_right_hand": Config.get_value("coordinates.right_hand"),
		"wheel_diameter": Config.get_value("player.pushrim_diameter"),
				}
	main.get_node("python_bridge").send_request({"command": "biofeedback_godot", "arg": arg})
