class_name WorldScaleCalculator
extends Node3D

@export var col_shape : CollisionShape3D
@export var scaled_parent_node : Node3D
		
func get_world_scale()->Vector3:
	if (col_shape.shape is BoxShape3D):
		
		return col_shape.shape.size * scaled_parent_node.get_scale()
	return Vector3.ZERO
