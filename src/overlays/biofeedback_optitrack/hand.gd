extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

# Selected side of the wheelchair (left or right)
@export_enum("left", "right") var side: String

var id_forearm_cluster
var id_simulator_reference
var coordinates_wheel_center
var position_wheel_key
var node_forearm_cluster 
var node_simulator_reference 

func _ready() -> void:
	
	# 
	if not main and not get_tree().get_root().has_node("optitrack"):
		var instance = preload("res://devices/optitrack/optitrack.tscn").instantiate()
		get_tree().current_scene.add_child.call_deferred(instance)
	
	_apply_side()

func _process(_delta):

	#if main:
	if Config.get_value("devices.optitrack.enabled"):
		
		# Get wheel center positions
		var _pos_center_wheel = Vector3( \
		Config.get_value(coordinates_wheel_center)[0], \
		Config.get_value(coordinates_wheel_center)[1], \
		Config.get_value(coordinates_wheel_center)[2]  \
		)
		
		# Get forearm cluster and simulator reference nodes from OptiTrack by their IDs
		if main:
			node_forearm_cluster = main.get_node("optitrack").get_node_by_id(id_forearm_cluster)
			node_simulator_reference = main.get_node("optitrack").get_node_by_id(id_simulator_reference)
		else:
			node_forearm_cluster = get_tree().current_scene.get_node("optitrack").get_node_by_id(id_forearm_cluster)
			node_simulator_reference = get_tree().current_scene.get_node("optitrack").get_node_by_id(id_simulator_reference)
		
		if node_forearm_cluster and node_simulator_reference:
			
			# Get the inverse global transform of the simulator reference
			var T0S = node_simulator_reference.global_transform.affine_inverse()
			
			# Apply forearm's global coordinates relative to the simulator's local frame
			self.global_transform = T0S * node_forearm_cluster.global_transform
			
			# Adjust position relative to the wheel center
			self.position -= _pos_center_wheel 
			self.position += $"..".get(position_wheel_key)

# Set IDs, references, and coordinate variables based on the selected side (left or right)
func _apply_side():
	if side == "left":
		id_forearm_cluster = 201
		id_simulator_reference = 102
		coordinates_wheel_center = "coordinates.left_wheel_center"
		position_wheel_key = "position_wheel_l"
	elif side == "right":
		id_forearm_cluster = 202
		id_simulator_reference = 102
		coordinates_wheel_center = "coordinates.right_wheel_center"
		position_wheel_key = "position_wheel_r"
