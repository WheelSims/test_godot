extends Node3D
@onready var main: Node = get_tree().get_root().get_node("main")

@export_enum("left", "right") var side: String

var id_hand_tracked
var id_repere_simulateur
var coordinates_wheel_center
var position_wheel_key

func _ready() -> void:
	_apply_side()

func _process(_delta):

	if main:
		if main.config.get_value("devices.optitrack.enabled"):
			
			var _pos_center_wheel = Vector3( \
			main.config.get_value(coordinates_wheel_center)[0], \
			main.config.get_value(coordinates_wheel_center)[1], \
			main.config.get_value(coordinates_wheel_center)[2]  \
			)
			
			var node_hand_tracked = main.get_node("optitrack").get_node_by_id(id_hand_tracked)
			var node_repere_simulateur = main.get_node("optitrack").get_node_by_id(id_repere_simulateur)
			
			if node_hand_tracked and node_repere_simulateur:
				
				var T0S = node_repere_simulateur.global_transform.affine_inverse()
				
				self.global_transform = T0S * node_hand_tracked.global_transform
				
				self.position -= _pos_center_wheel 
				self.position += $"..".get(position_wheel_key)

func _apply_side():
	if side == "left":
		id_hand_tracked = 201
		id_repere_simulateur = 102
		coordinates_wheel_center = "coordinates.left_wheel_center"
		position_wheel_key = "position_wheel_l"
	elif side == "right":
		id_hand_tracked = 202
		id_repere_simulateur = 102
		coordinates_wheel_center = "coordinates.right_wheel_center"
		position_wheel_key = "position_wheel_r"
