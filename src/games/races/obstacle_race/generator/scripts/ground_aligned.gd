class_name GroundAligned
extends Node3D

@onready var down_ray: RayCast3D = $RayCast3D


func transform_correction() -> float:
	var collision_point: Vector3 = Vector3.ZERO
	var collision_normal: Vector3
	if down_ray.is_colliding():
		collision_point = down_ray.get_collision_point()
		collision_normal = down_ray.get_collision_normal()
	if not down_ray.is_colliding():
		return 0
	down_ray.enabled = false
	return (global_position - collision_point).y


func _enter_tree() -> void:
	await get_tree().process_frame
	var y_offset = transform_correction()
	position -= y_offset * Vector3.UP
