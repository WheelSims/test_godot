@tool
class_name WorldScaleCalculator
extends Node3D
## Script used to classify object in types and calculate their size in the race_width axis.

enum ObjectType { UnitWall, ScalableWall, Obstacle }
##If a node is scaled. It must be this one
@export var visual_instance: VisualInstance3D
##The shape of the collision_shape must be one BoxShape3D.
@export var collision_shape: CollisionShape3D

@export var object_type: ObjectType
@export var area3D: Area3D


func _ready() -> void:
	if not visual_instance.is_node_ready():
		visual_instance.ready.connect(get_precise_size)
	else:
		get_precise_size()


## Calculate baked_sizes_dict to give size for every rotations. If no argument is filled: it calculates one size for the default rotation.
func write_sizes_with_rotation(rotations: Array[float] = []) -> Dictionary:
	var origin_rot = visual_instance.rotation_degrees.y
	var baked_sizes_dict: Dictionary = {}
	if rotations.size() == 0:
		rotations.append(origin_rot)

	for rot in rotations:
		visual_instance.rotation_degrees.y = rot
		baked_sizes_dict[rot] = get_precise_size()
	visual_instance.rotation_degrees.y = origin_rot
	return baked_sizes_dict


## Calculate the z-axis size that takes the object in the current state (current rotation)
func get_precise_size() -> Vector3:
	var box_shape: BoxShape3D
	if collision_shape.shape is BoxShape3D:
		box_shape = collision_shape.shape
	else:
		push_error("CollisionShape have to be one BoxShape3D")
		return Vector3.ZERO
	var aabb = visual_instance.global_transform * AABB(collision_shape.position, box_shape.size)

	var z_range = Vector2(0, 0)
	var y_range = Vector2(0, 0)
	var x_range = Vector2(0, 0)

	for x in [aabb.position.x, aabb.position.x + aabb.size.x]:
		for y in [aabb.position.y, aabb.position.y + aabb.size.y]:
			for z in [aabb.position.z, aabb.position.z + aabb.size.z]:
				z_range.x = min(z_range.x, z)
				z_range.y = max(z_range.y, z)
				y_range.x = min(y_range.x, y)
				y_range.y = max(y_range.y, y)
				x_range.x = min(x_range.x, x)
				x_range.y = max(x_range.y, x)

	var baked_size_z = z_range.y - z_range.x
	var baked_size_y = y_range.y - y_range.x
	var baked_size_x = x_range.y - x_range.x
	#print(baked_size_z)
	return Vector3(baked_size_x, baked_size_y, baked_size_z)


func get_size() -> Vector3:
	var scale: Vector3 = Vector3.ZERO
	var box_shape: BoxShape3D
	if collision_shape.shape is BoxShape3D:
		box_shape = collision_shape.shape
	else:
		push_error("CollisionShape have to be one BoxShape3D")
		return scale
	scale = box_shape.size * visual_instance.scale
	return scale


## Scale the object from original_size to value.
func scale_from_real_size(value: float, original_size: float) -> void:
	scale *= value / original_size
