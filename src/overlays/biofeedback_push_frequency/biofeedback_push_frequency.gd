extends Control

# ---------------------------------------------------------------------- #
# GUI overlay for displaying mean push frequency from biofeedback data
# - receives mean push frequency values from the device Python bridge
# - Displays the current mean push frequency whithin a slider
# ---------------------------------------------------------------------- #

# Slider parameters
@export_category("Slider parameters")
@export var min_value = 0.0
@export var max_value = 2.5

@export var min_target_value = 0.0
@export var max_target_value = 1.2

# UI elements
@export_category("Nodes")
@export var node_min_value: Node
@export var node_max_value: Node
@export var node_min_target_value: Node
@export var node_max_target_value: Node
@export var node_value: Node
@export var node_slider_zone: Node
@export var node_slider: Node
@export var node_target_zone: Node

@export var node_current_value: Node
@export var node_red_zone_left: Node
@export var node_green_zone_left: Node
@export var node_red_zone_right: Node
@export var node_green_zone_right: Node
@export var node_frame_overlay: Node
@export var node_all_overlay: Node
@export var node_arrows: Node
@export var node_head_arrow: Node
@export var node_line_arrow: Node
@export var node_arrow_left: Node
@export var node_arrow_right: Node


var temp_current_value = 0.0

@export var time_shake_scale = 0.2
@export var time_shake_rotation = 0.2
@export var deg = 0.2
@export var sca = 1.05
var tween_arrow_left: Tween
var tween_arrow_right: Tween
var tween_arrow_color: Tween
var tween_current_value: Tween

# Push frequency value from python script biofeedback
@export var current_value = 0.0
var height_slider = 120

var slider_value = 0.0

# Connection flags and request arguments
var connected = false
var biofeedback_args


func _process(_delta) -> void:
	# Once start the analysis by sending a request to the python bridge
	if Globals.main.has_node("PythonBridge"):
		if Globals.main.get_node("PythonBridge")._udp_receiver_connected and not connected:
			connected = true
			_update_arg()
			Globals.main.get_node("PythonBridge").send(
				"biofeedback_update", biofeedback_args, "start"
			)
	# Reset the connected flag if the python bridge is disconnected
	else:
		if connected:
			connected = false

	# Update the slider if the process is connected
	if connected:
		if Globals.main.has_node("PythonBridge"):
			var data = Globals.main.get_node("PythonBridge").receive("biofeedback_push_frequency")
			_update_slider(data)

	# Should we quit
	if not Config.get_value("overlays.biofeedback_push_frequency.enabled"):
		# Stop the biofeedback from python bridge if this overlays is shut down
		if (
			Globals.main.has_node("PythonBridge")
			and connected
			and not Config.get_value("overlays.biofeedback_push_pattern.enabled")
		):
			# Tell the python bridge to stop the repeating update process
			Globals.main.get_node("PythonBridge").send("biofeedback_update", {}, "stop")
			# Send a final request to reset the biofeedback script data
			_update_arg()
			Globals.main.get_node("PythonBridge").send("biofeedback_stop", biofeedback_args, "once")
		# Remove the overlay node from the scene tree
		queue_free()


# Update the slider with slider parameters and the received mean push frequency
func _update_slider(data):
	if data is Dictionary and data.has("data") and data["data"].size() > 0:
		if data["command"] == "biofeedback_update":
			var side = data["data"].keys()[0]
			if data["data"][side].has("mean_push_frequency"):

				current_value = data["data"][side]["mean_push_frequency"]

				node_red_zone_left.size.y = height_slider
				node_red_zone_right.size.y = height_slider
				node_max_value.text = str(max_value)
				
				node_green_zone_left.size.y = height_slider * (max_target_value/max_value)
				node_green_zone_right.size.y = height_slider * (max_target_value/max_value)
				node_max_target_value.text = str(max_target_value)
				node_max_target_value.position.y = - height_slider * (max_target_value/max_value)

				var node_source
				
				if current_value < max_target_value:
					node_source = node_green_zone_left
				else:
					node_source = node_red_zone_left
					
				var source_style = node_source.get_theme_stylebox("panel")
				
				var style = StyleBoxFlat.new()
				style.bg_color = source_style.bg_color
				style.corner_radius_top_left = 10
				style.corner_radius_top_right = 10
				
				node_current_value.add_theme_stylebox_override("panel", style)

				if current_value <= 0:
					node_head_arrow.get_theme_stylebox("panel").bg_color = Color(0.03, 0.03, 0.03)
					node_line_arrow.get_theme_stylebox("panel").bg_color = Color(0.03, 0.03, 0.03)
				elif current_value > 0 and (tween_current_value == null or tween_current_value.is_valid() == false):
					node_head_arrow.get_theme_stylebox("panel").bg_color = source_style.bg_color
					node_line_arrow.get_theme_stylebox("panel").bg_color = source_style.bg_color
					slider_value = current_value
					node_current_value.size.y = height_slider * (slider_value/max_value)
					node_arrows.position.y = - height_slider * (slider_value/max_value)

				if (tween_arrow_left == null or !tween_arrow_left.is_running()) and (tween_arrow_right == null or !tween_arrow_right.is_running()):
					node_arrow_left.scale = 0.15 * Vector2.ONE
					node_arrow_right.scale = 0.15 * Vector2.ONE
					tween_arrow_left = create_tween()
					tween_arrow_left.tween_property(node_arrow_left, "scale", Vector2.ONE * 0.10, 0.1)
					tween_arrow_left.tween_property(node_arrow_left, "scale", Vector2.ONE * 0.15, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
					tween_arrow_right = create_tween()
					tween_arrow_right.tween_property(node_arrow_right, "scale", Vector2.ONE * 0.10, 0.1)
					tween_arrow_right.tween_property(node_arrow_right, "scale", Vector2.ONE * 0.15, 0.4).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# Update the arguments to send the requests to the python bridge
func _update_arg():
	biofeedback_args = {
		"coordinates_left_wheel_center": Config.get_value("coordinates.left_wheel_center"),
		"coordinates_right_wheel_center": Config.get_value("coordinates.right_wheel_center"),
		"coordinates_left_hand": Config.get_value("coordinates.left_hand"),
		"coordinates_right_hand": Config.get_value("coordinates.right_hand"),
		"wheel_diameter": Config.get_value("player.pushrim_diameter"),
	}
