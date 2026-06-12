extends Node3D

# Selected side of the wheelchair (left or right)
@export_enum("left", "right") var side: String
# Selected cluster of the wheelchair (forearm or arm)
@export_enum("forearm", "arm") var cluster: String

var id_forearm_cluster
var node_forearm_cluster


func _ready() -> void:
	_apply_side()


func _process(_delta):
	if Config.get_value("devices.optitrack.enabled"):
		# Get forearm cluster and simulator reference nodes from OptiTrack by their IDs
		if Globals.main:
			node_forearm_cluster = Globals.main.get_node("optitrack").get_node_by_id(
				id_forearm_cluster
			)
		else:  # If overlay scene runs standalone (outside Globals.main)
			node_forearm_cluster = get_tree().current_scene.get_node("optitrack").get_node_by_id(
				id_forearm_cluster
			)

		if node_forearm_cluster:
			self.transform = node_forearm_cluster.transform


# Set IDs, references, and coordinate variables based on the selected side (left or right)
func _apply_side():
	if side == "left":
		if cluster == "forearm":
			id_forearm_cluster = 201
		else:
			id_forearm_cluster = 301
	elif side == "right":
		if cluster == "forearm":
			id_forearm_cluster = 202
		else:
			id_forearm_cluster = 302
