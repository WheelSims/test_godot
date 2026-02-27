class_name ObjectInfo
extends Resource
## ObjectInfo contains informations (z_sizes and type) and the scene of an object.
##
## z_sizes is a dictionary  with the sizes in the race width axis (values) depending on the y_axis rotation of the object (keys).
## type is the type of the object if it's a WorldScaleCalculator: UnitWall, ScalableWall or Obstacle

@export var scene : PackedScene
## Dictionary that gives: rotation → z axis size
@export var z_sizes : Dictionary   
## type is the type of the object if it's a WorldScaleCalculator: UnitWall, ScalableWall or Obstacle
@export var type : WorldScaleCalculator.ObjectType

func is_valid()->bool:
	if z_sizes.is_empty():
		return false
	elif not is_instance_valid(scene):
		return false
	return true
