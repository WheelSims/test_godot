extends MultiMeshInstance3D 

# Selected side of the wheelchair (left or right)
@export_enum("left", "right") var side: String 

var frame_limit = 100
var trail_size = 0.15
var offset_trail
var layer
var coordinates_hand
var node_hand_key
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
	
	var debut = Time.get_ticks_usec()
	# Compute hand position for trail: hand coordinates in cluster space transformed to world space with offset
	var _pos_hand = Vector3.ZERO 
	if Config.get_value("devices.optitrack.enabled"): 
		# Get hand coordinates relative to cluster
		_pos_hand = Vector3(Config.get_value(coordinates_hand)[0], Config.get_value(coordinates_hand)[1], Config.get_value(coordinates_hand)[2]) 
		
		# Transform hand position to world space and apply trail offset
		var hand_node = $"..".get_node(node_hand_key) 
		var pos_hand = hand_node.position + hand_node.global_transform.basis * _pos_hand + offset_trail 
		
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
	
	var fin = Time.get_ticks_usec()
	var temp_execution = (fin - debut)/1_000.0
	print("Temps d'exécution trail_hand : %.6f ms" % temp_execution)

# Set trail offset, rendering layer, and hand references based on the selected side (left or right)
func _apply_side(): 
	if side == "left": 
		offset_trail = Vector3(0, 0, -0.05) 
		layer = 1 << 5 
		coordinates_hand = "coordinates.left_hand" 
		node_hand_key = "forearm_cluster_left" 
	elif side == "right": 
		offset_trail = Vector3(0, 0, 0.05) 
		layer = 1 << 6 
		coordinates_hand = "coordinates.right_hand" 
		node_hand_key = "forearm_cluster_right"


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
