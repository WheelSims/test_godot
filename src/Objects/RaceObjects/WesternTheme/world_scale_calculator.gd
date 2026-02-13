class_name WorldScaleCalculator
extends Node3D

@export var visual_instance: VisualInstance3D
var size_z: float = 0
func _ready() -> void:
	if not visual_instance.is_node_ready():
		visual_instance.ready.connect(get_precise_size_z)
	else:
		get_precise_size_z()
		
func get_precise_size_z()->float:
	var aabb = visual_instance.global_transform * visual_instance.get_aabb()
		
	var min_z = INF
	var max_z = -INF
	
	for x in [aabb.position.x, aabb.position.x + aabb.size.x]:
		for y in [aabb.position.y, aabb.position.y + aabb.size.y]:
			for z in [aabb.position.z, aabb.position.z + aabb.size.z]:
				#var p = t * Vector3(x,y,z)
				min_z = min(min_z, z)
				max_z = max(max_z, z)
	
	size_z = max_z - min_z
	return size_z
	
