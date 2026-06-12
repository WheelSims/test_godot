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

@export var min_target_value = 0.4
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
@export var node_green_zone: Node

# Push frequency value from python script biofeedback
var value = 0.0  #!TODO Change name for current_value

# Connection flags and request arguments
var connected = false
var arg  #!TODO Change name for something more specific


func _process(_delta) -> void:
	# Once start the analysis by sending a request to the python bridge
	if Globals.main.has_node("python_bridge"):
		if Globals.main.get_node("python_bridge")._udp_receiver_connected and not connected:
			connected = true
			_update_arg()
			Globals.main.get_node("python_bridge").send("biofeedback_update", arg, "start")
	# Reset the connected flag if the python bridge is disconnected
	else:
		if connected:
			connected = false

	# Update the slider if the process is connected
	if connected:
		if Globals.main.has_node("python_bridge"):
			var data = Globals.main.get_node("python_bridge").receive("biofeedback_push_frequency")
			_update_slider(data)

	# Should we quit
	if not Config.get_value("overlays.biofeedback_push_frequency.enabled"):
		# Stop the biofeedback from python bridge if this overlays is shut down
		if (
			Globals.main.has_node("python_bridge")
			and connected
			and not Config.get_value("overlays.biofeedback_optitrack.enabled")
		):
			# Tell the python bridge to stop the repeating update process
			Globals.main.get_node("python_bridge").send("biofeedback_update", {}, "stop")
			# Send a final request to reset the biofeedback script data
			_update_arg()
			Globals.main.get_node("python_bridge").send("biofeedback_stop", arg, "once")
		# Remove the overlay node from the scene tree
		queue_free()


# Update the slider with slider parameters and the received mean push frequency
func _update_slider(data):
	if data is Dictionary and data.has("data") and data["data"].size() > 0:
		if data["command"] == "biofeedback_update":
			var side = data["data"].keys()[0]
			if data["data"][side].has("mean_push_frequency"):
				value = data["data"][side]["mean_push_frequency"]

	node_min_value.text = str(min_value)
	node_max_value.text = str(max_value)
	node_value.text = str(snappedf(value, 0.1))

	node_slider.position.y = (
		node_slider_zone.size.y
		- (value - min_value) * node_slider_zone.size.y / (max_value - min_value)
	)
	node_slider.size.x = node_slider_zone.size.x

	node_target_zone.position.y = (
		node_slider_zone.size.y
		- (min_target_value - min_value) * node_slider_zone.size.y / (max_value - min_value)
	)
	node_green_zone.size.y = (
		node_slider_zone.size.y * (max_target_value - min_target_value) / (max_value - min_value)
	)

	node_min_target_value.text = str(min_target_value)
	node_max_target_value.text = str(max_target_value)

	node_max_target_value.position.y = node_green_zone.size.y


# Update the arguments to send the requests to the python bridge
func _update_arg():
	arg = {
		"coordinates_left_wheel_center": Config.get_value("coordinates.left_wheel_center"),
		"coordinates_right_wheel_center": Config.get_value("coordinates.right_wheel_center"),
		"coordinates_left_hand": Config.get_value("coordinates.left_hand"),
		"coordinates_right_hand": Config.get_value("coordinates.right_hand"),
		"wheel_diameter": Config.get_value("player.pushrim_diameter"),
	}
