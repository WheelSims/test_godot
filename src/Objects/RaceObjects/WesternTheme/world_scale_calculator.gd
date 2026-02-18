@tool
class_name WorldScaleCalculator
extends Node3D

enum ObjectType {UnitWall, ScalableWall, Obstacle}
##If a node is scaled. It must be this one
@export var visual_instance: VisualInstance3D
##The shape of the collision_shape must be one BoxShape3D.
@export var collision_shape: CollisionShape3D
@export var baked_size_z: float = 0
@export var object_type: ObjectType
func _ready() -> void:
	if not visual_instance.is_node_ready():
		visual_instance.ready.connect(get_precise_size_z)
	else:
		get_precise_size_z()

func get_precise_size_z()->float:
	var box_shape: BoxShape3D
	if collision_shape.shape is BoxShape3D:
		box_shape = collision_shape.shape
	else:
		push_error("CollisionShape have to be one BoxShape3D")
		return 0
	var aabb = visual_instance.global_transform * AABB(collision_shape.position, box_shape.size)
		
	var min_z = INF
	var max_z = -INF
	
	for x in [aabb.position.x, aabb.position.x + aabb.size.x]:
		for y in [aabb.position.y, aabb.position.y + aabb.size.y]:
			for z in [aabb.position.z, aabb.position.z + aabb.size.z]:
				#var p = t * Vector3(x,y,z)
				min_z = min(min_z, z)
				max_z = max(max_z, z)
	
	baked_size_z = max_z - min_z
	#print(baked_size_z)
	return baked_size_z
	
func scale_from_real_size(value: float)->void:
	if baked_size_z>0:
		scale *= value/baked_size_z
	else:
		push_error("Cannot scale object because it's not baked.")
