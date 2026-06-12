class_name ObjectInfo
extends Resource
## ObjectInfo contains informations (z_sizes and type) and the scene of an object.
##
## z_sizes is a dictionary  with the sizes in the race width axis (values) depending on the y_axis rotation of the object (keys).
## type is the type of the object if it's a WorldScaleCalculator: UnitWall, ScalableWall or Obstacle

@export var scene: PackedScene
## Dictionary that gives: rotation -> Vector3 sizes
@export var sizes: Dictionary
## Dictionary that gives: rotation -> z_sizes in z_axis
var z_sizes: Dictionary
## Don't depend on the rotation. Scale on the local axis.
@export var local_scale: Vector3
## type is the type of the object if it's a WorldScaleCalculator: UnitWall, ScalableWall or Obstacle
@export var type: WorldScaleCalculator.ObjectType


func is_valid() -> bool:
	if sizes.is_empty():
		return false
	elif not is_instance_valid(scene):
		return false
	return true


func get_z_sizes() -> Dictionary:
	if not z_sizes.is_empty() and z_sizes.size() == sizes.size():
		return z_sizes
	for key in sizes.keys():
		z_sizes[key] = sizes[key].z
	return z_sizes
