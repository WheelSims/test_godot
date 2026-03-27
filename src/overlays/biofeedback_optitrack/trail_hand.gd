extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

# Selected side of the wheelchair (left or right)
@export_enum("left", "right") var side: String

var points = []
var frame_limit = 100
var trail_size = 0.02
var trails = []
var i = 0

var offset_trail
var layer
var coordinates_hand
var node_hand_key

var pos_trail = Vector3(0, 0, 0)

func _ready() -> void:
	_apply_side()

func _process(_delta):

	if $"..".trails_visibled:
		var _pos_hand = Vector3(0, 0, 0)
		
		if main:
			if main.config.get_value("devices.optitrack.enabled"):
				
				_pos_hand = Vector3( \
					main.config.get_value(coordinates_hand)[0], \
					main.config.get_value(coordinates_hand)[1], \
					main.config.get_value(coordinates_hand)[2]  \
					)

		var pos_hand = $"..".get_node(node_hand_key).position + $"..".get_node(node_hand_key).global_transform.basis * _pos_hand
		
		if i >= frame_limit:
			points.remove_at(0)
		points.append(pos_hand)
		i += 1

		for trail in trails:
			trail.queue_free()
		trails.clear()

		for u in range(1, len(points)):

			var alpha = float(u) / len(points)
			alpha = pow(alpha, 1.5)
			
			var trail = create_trail(points[u], alpha)
			trails.append(trail)

func create_trail(pos: Vector3, alpha: float) -> MeshInstance3D:

	var mesh = SphereMesh.new()
	mesh.radius = trail_size * alpha
	mesh.height = trail_size * 2 * alpha
	mesh.radial_segments = 8
	mesh.rings = 8
	
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = pos + offset_trail
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 0, 0, alpha)
	instance.material_override = mat
	instance.layers = layer
	
	add_child(instance)
	return instance

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
		
