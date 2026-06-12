## This scene/script is used to visualize objects tracked by OptiTrack.
## A CAD model can be associated by ID, or a basic cube is displayed by default
extends Node3D

@export var available_models: Dictionary[String, PackedScene]

var id_node = []


func _process(_delta: float) -> void:
	var optitrack = get_node_or_null("optitrack")
	if optitrack:
		for child in optitrack.get_children():
			# Display the CAD model associated with the tracked object's ID
			if child.name in available_models and len(child.get_children()) == 0:
				var scene: PackedScene = available_models[child.name]
				var instance = scene.instantiate()
				child.add_child(instance)
			# Display a default cube when no CAD model is associated with the ID
			elif child.name not in available_models and len(child.get_children()) == 0:
				var mesh_instance = MeshInstance3D.new()
				var box = BoxMesh.new()
				box.size = Vector3(0.15, 0.15, 0.15)
				mesh_instance.mesh = box
				child.add_child(mesh_instance)
