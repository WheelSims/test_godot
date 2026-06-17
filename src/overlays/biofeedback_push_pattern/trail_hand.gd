extends MultiMeshInstance3D

# ---------------------------------------------------------------------- #
# Visualization of hand trajectories using OptiTrack tracking
# - hand positions are computed from forearm cluster coordinates
# - positions are transformed to world space with a side-specific offset
# - a MultiMesh is used to render the motion trail efficiently
# ---------------------------------------------------------------------- #

# Selected side of the wheelchair (left or right)
@export_enum("left", "right") var side: String

# Nodes
@export var  node_forearm_cluster_left: Node
@export var node_forearm_cluster_right: Node

# Trail rendering parameters
var frame_limit = 100
var trail_size = 0.15

# Variables depending on side
var offset_trail
var layer
var coordinates_hand
var node_hand_key

# Stored trail positions and transparency values
var list_pos_hand = []
var list_alpha = []


func _ready() -> void:
	_apply_side()

	# Initialize scale values along the trail based on point age
	for i in range(frame_limit):
		var t = float(i) / (frame_limit - 1)
		list_alpha.append(pow(t, 2.0))

	init_multimesh()


func _process(_delta):
	# Compute hand position for trail: hand coordinates in cluster space transformed to world
	# space with offset.
	var local_pos_hand = Vector3.ZERO
	if Config.get_value("devices.optitrack.enabled"):
		# Get hand coordinates relative to cluster
		local_pos_hand = Vector3(
			Config.get_value(coordinates_hand)[0],
			Config.get_value(coordinates_hand)[1],
			Config.get_value(coordinates_hand)[2]
		)

		# Transform hand position to world space and apply trail offset
		var hand_node = node_hand_key
		var pos_hand = (
			hand_node.position + hand_node.global_transform.basis * local_pos_hand + offset_trail
		)

		# Update hand positions list to maintain trail over time
		if len(list_pos_hand) < frame_limit:
			list_pos_hand.append(pos_hand)
		else:
			list_pos_hand.remove_at(0)
			list_pos_hand.append(pos_hand)

		# Update multimesh instances to render trail points with position and scale
		for i in range(len(list_pos_hand)):
			var t = Transform3D()
			t.origin = list_pos_hand[i]
			t.basis = Basis().scaled(Vector3.ONE * trail_size * list_alpha[i])

			self.multimesh.set_instance_transform(i, t)


# Set trail offset, rendering layer, and hand references based on the selected side (left or right)
func _apply_side():
	if side == "left":
		offset_trail = Vector3(0, 0, -0.05)
		layer = 1 << 5
		coordinates_hand = "coordinates.left_hand"
		node_hand_key = node_forearm_cluster_left
	elif side == "right":
		offset_trail = Vector3(0, 0, 0.05)
		layer = 1 << 6
		coordinates_hand = "coordinates.right_hand"
		node_hand_key = node_forearm_cluster_right


# Initialize a MultiMesh instance used to render the trail
func init_multimesh():
	# Create and set the multimesh
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = frame_limit

	# Create the mesh for each trail point
	var mesh = SphereMesh.new()
	mesh.radius = trail_size
	mesh.height = trail_size * 2
	mesh.radial_segments = 8
	mesh.rings = 8
	mm.mesh = mesh

	self.multimesh = mm
	self.layers = layer

	# Set the color of the trail meshes
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0, 1)
	self.material_override = mat

	# Initialize all multimesh instances
	var t = Transform3D()
	t.basis = Basis().scaled(Vector3.ONE * trail_size)
	for i in range(frame_limit):
		mm.set_instance_transform(i, t)
