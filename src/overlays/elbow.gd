extends Node3D

@onready var node_acromion = $acromion
@onready var node_lateral_epicondyl = $lateral_epicondyl
@onready var node_medial_epicondyl = $medial_epicondyl
@onready var node_radial_styloid = $radial_styloid
@onready var node_ulnar_styloid = $ulnar_styloid

@onready var node_forearm_frame = $forearm_frame
@onready var node_arm_frame = $arm_frame

@onready var node_forearm_cluster = $"../forearm_cluster_right"
@onready var node_arm_cluster = $"../arm_cluster_right"

var coordinates_lateral_epicondyl = "coordinates.lateral_epicondyl_right"
var coordinates_medial_epicondyl = "coordinates.medial_epicondyl_right"
var coordinates_radial_styloid = "coordinates.radial_styloid_right"
var coordinates_ulnar_styloid = "coordinates.ulnar_styloid_right"
var coordinates_acromion = "coordinates.acromion_right"

var list

var flexion_GPT = 0
var flexion_euler = 0

var beta = 0
var alpha = 0
var gamma = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	list = [ \
	{"coordinates": coordinates_lateral_epicondyl, "node": node_lateral_epicondyl, "node_frame": node_arm_cluster}, \
	{"coordinates": coordinates_medial_epicondyl, "node": node_medial_epicondyl, "node_frame": node_arm_cluster}, \
	{"coordinates": coordinates_acromion, "node": node_acromion, "node_frame": node_arm_cluster}, \
	{"coordinates": coordinates_radial_styloid, "node": node_radial_styloid, "node_frame": node_forearm_cluster}, \
	{"coordinates": coordinates_ulnar_styloid, "node": node_ulnar_styloid, "node_frame": node_forearm_cluster}, \
	]

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
	# 
	for i in list:
		
		var coordinates = i["coordinates"]
		var node = i["node"]
		var node_frame = i["node_frame"]
		
		# Get object coordinates relative to cluster
		var _pos = Vector3(Config.get_value(coordinates)[0], Config.get_value(coordinates)[1], Config.get_value(coordinates)[2]) 
			
		# Transform object position to world space
		var pos = node_frame.position + node_frame.global_transform.basis * _pos
		node.position = pos
	
	## Create local coordinate systems
	# Arm coordinate system
	var arm_coordinate_system = {}
	arm_coordinate_system["origin"] = node_acromion.position

	arm_coordinate_system["y"] = node_acromion.position - 0.5 * (node_lateral_epicondyl.position + node_medial_epicondyl.position)
	arm_coordinate_system["z"] = node_lateral_epicondyl.position - node_medial_epicondyl.position

	arm_coordinate_system["z"] = arm_coordinate_system["z"].normalized()
	arm_coordinate_system["x"] = arm_coordinate_system["y"].cross(arm_coordinate_system["z"]).normalized()
	arm_coordinate_system["y"] = arm_coordinate_system["z"].cross(arm_coordinate_system["x"]).normalized()
	
	
	arm_coordinate_system["transform"] = Transform3D( \
	Basis(arm_coordinate_system["x"], arm_coordinate_system["y"], arm_coordinate_system["z"]),\
	arm_coordinate_system["origin"] \
	)

	node_arm_frame.transform = arm_coordinate_system["transform"]

	# Forearm coordinate system
	var forearm_coordinate_system = {}
	forearm_coordinate_system["origin"] = node_ulnar_styloid.position

	forearm_coordinate_system["y"] = 0.5 * (node_lateral_epicondyl.position + node_medial_epicondyl.position) - node_ulnar_styloid.position
	forearm_coordinate_system["z"] = node_radial_styloid.position - node_ulnar_styloid.position

	forearm_coordinate_system["z"] = forearm_coordinate_system["z"].normalized()
	forearm_coordinate_system["x"] = forearm_coordinate_system["y"].cross(forearm_coordinate_system["z"]).normalized()
	forearm_coordinate_system["y"] = forearm_coordinate_system["z"].cross(forearm_coordinate_system["x"]).normalized()
	
	
	forearm_coordinate_system["transform"] = Transform3D( \
	Basis(forearm_coordinate_system["x"], forearm_coordinate_system["y"], forearm_coordinate_system["z"]),\
	forearm_coordinate_system["origin"] \
	)

	node_forearm_frame.transform = forearm_coordinate_system["transform"]

	## Get the series of homogeneous tranforms between both segments
	var forearm_in_arm = arm_coordinate_system["transform"].affine_inverse() * forearm_coordinate_system["transform"]
	
	## Get biomechanics angles
	var R = forearm_in_arm.basis

	var r01 = R.y.x
	var r11 = R.y.y
	var r20 = R.x.z
	var r21 = R.y.z
	var r22 = R.z.z

	# ZXY
	beta  = asin(r21)
	alpha = atan2(-r01, r11)
	gamma = atan2(-r20, r22)

	alpha = rad_to_deg(alpha)
	beta  = rad_to_deg(beta)
	gamma = rad_to_deg(gamma)
	
	$"../Label".text = ("flexion / hyperextension : " + str(snappedf(alpha, 0.1)))
	$"../Label2".text = ("carrying angle                    : " + str(snappedf(beta, 0.1)))
	$"../Label3".text = ("pronation / supination     : " + str(snappedf(gamma, 0.1)))
