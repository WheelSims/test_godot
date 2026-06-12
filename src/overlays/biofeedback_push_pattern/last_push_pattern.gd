extends MultiMeshInstance3D

# ---------------------------------------------------------------------- #
# Visualization of wheelchair push patterns (biofeedback system)
# - retrieves push trajectories from a Python bridge over UDP
# - supports multiple push patterns (last, penultimate, antepenultimate)
# - side-specific configuration for left and right wheels
# - transforms raw data into wheel-centered local coordinates
# - renders trajectories efficiently using a MultiMesh
# ---------------------------------------------------------------------- #

# Selected side of the wheelchair (left or right)
@export_enum("left", "right") var side: String
# Selected last push pattern from Python (1 -> last, 2 -> penultimate, 3 -> antepenultimate)
@export_enum("last_push_pattern_1", "last_push_pattern_2", "last_push_pattern_3")
var last_push_pattern: String

# Variables
var positions := []
var trail_size := 0.11

# Variables depending on side
var layer
var coordinates_wheel_center
var offset_trail
var virtual_wheel

# Connection flags and request arguments
var connected = false
var arg


func _ready() -> void:
	_apply_side()
	_init_multimesh()
	_update_multimesh()


func _process(_delta: float) -> void:
	# Once start the analysis by sending a request to the python bridge
	if Globals.main:
		if Globals.main.has_node("python_bridge"):
			if Globals.main.get_node("python_bridge")._udp_receiver_connected and not connected:
				connected = true
				_update_arg()
				Globals.main.get_node("python_bridge").send("biofeedback_update", arg, "start")
		# Reset the connected flag if the python bridge is disconnected
		else:
			if connected:
				connected = false

	# Update loop process if the process is connected
	if connected:
		visible = true
		if Globals.main.has_node("python_bridge"):
			var data = Globals.main.get_node("python_bridge").receive(
				last_push_pattern + "_" + side
			)

			if data is Dictionary and data.has("data") and data["data"].size() > 0:
				if data["command"] == "biofeedback_update":
					if data["data"].keys()[0] == side:
						var value = data["data"][side][last_push_pattern]
						positions = parse_trail_points(value)
						_update_multimesh()
	else:
		visible = false

	# Should we quit
	if not Config.get_value("overlays.biofeedback_optitrack.enabled"):
		# Stop the biofeedback from python bridge if this overlays is shut down
		if (
			Globals.main.has_node("python_bridge")
			and connected
			and not Config.get_value("overlays.biofeedback_push_frequency.enabled")
		):
			# Tell the python bridge to stop the repeating update process
			Globals.main.get_node("python_bridge").send("biofeedback_update", {}, "stop")
			# Send a final request to reset the biofeedback script data
			_update_arg()
			Globals.main.get_node("python_bridge").send("biofeedback_stop", arg, "once")
		# Remove the overlay node from the scene tree
		queue_free()


# Update the arguments to send the requests to the python bridge
func _update_arg():
	arg = {
		"coordinates_left_wheel_center": Config.get_value("coordinates.left_wheel_center"),
		"coordinates_right_wheel_center": Config.get_value("coordinates.right_wheel_center"),
		"coordinates_left_hand": Config.get_value("coordinates.left_hand"),
		"coordinates_right_hand": Config.get_value("coordinates.right_hand"),
		"wheel_diameter": Config.get_value("player.pushrim_diameter"),
	}


# Set layer, references, and coordinate variables based on the selected side (left or right)
func _apply_side():
	if side == "left":
		layer = 1 << 7
		coordinates_wheel_center = "coordinates.left_wheel_center"
		offset_trail = 0.1
		virtual_wheel = "../wheel_left"
	elif side == "right":
		layer = 1 << 8
		coordinates_wheel_center = "coordinates.right_wheel_center"
		offset_trail = -0.1
		virtual_wheel = "../wheel_right"


# Initialize a MultiMesh instance used to render the push pattern trail
func _init_multimesh():
	for i in range(101):
		positions.append(Vector3(0, 0, 0))

	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = positions.size()

	var mesh = SphereMesh.new()
	mesh.radius = trail_size
	mesh.height = trail_size * 2
	mesh.radial_segments = 8
	mesh.rings = 8
	mm.mesh = mesh

	self.multimesh = mm
	self.layers = layer

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.8, 0, 1)
	self.material_override = mat


# Update push pattern displayed
func _update_multimesh():
	for i in range(positions.size()):
		var t = Transform3D()
		t.origin = positions[i]
		t.basis = Basis().scaled(Vector3.ONE * trail_size)
		multimesh.set_instance_transform(i, t)


# Convert raw Python trajectory data into local Vector3 positions
func parse_trail_points(data):
	# Get wheel center positions
	var pos_center_wheel = Vector3(
		Config.get_value(coordinates_wheel_center)[0],
		Config.get_value(coordinates_wheel_center)[1],
		get_node(virtual_wheel).position[2] + offset_trail
	)

	var result: Array = []

	for p in data:
		p[2] = 0  # 2D projection
		result.append(Vector3(p[0], p[1], p[2]) - pos_center_wheel)

	return result
