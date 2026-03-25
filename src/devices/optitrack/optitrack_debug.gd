extends Node3D

# ---------------------------------------------------------------------- #
# This scene is used to visualize objects tracked by OptiTrack
# A CAD model can be associated by ID, or a basic cube is displayed by default
# ---------------------------------------------------------------------- #

@export var available_models: Dictionary[String, PackedScene] = {
	"101": preload("res://objects/optitrack/estrade/estrade.tscn"),
	"102": preload("res://objects/optitrack/simulateur/simulateur.tscn"),
	"999": preload("res://objects/optitrack/probe/probe.tscn"),
	"201": preload("res://objects/optitrack/forearm cluster left/forearm_cluster_left.tscn"),
	"202": preload("res://objects/optitrack/forearm cluster right/forearm_cluster_right.tscn"),
}

var id_node = []


func _ready() -> void:
	pass


func _process(_delta: float) -> void:
	for child in $optitrack.get_children():
		if child.name in available_models and len(child.get_children()) == 0:
			var scene: PackedScene = available_models[child.name]
			var instance = scene.instantiate()
			child.add_child(instance)
		elif child.name not in available_models and len(child.get_children()) == 0:
			var mesh_instance = MeshInstance3D.new()

			var box = BoxMesh.new()
			box.size = Vector3(0.15, 0.15, 0.15)
			mesh_instance.mesh = box
			child.add_child(mesh_instance)
