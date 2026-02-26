extends MeshInstance3D
class_name CarVisuals

@export var wheels: Array[MeshInstance3D]
@export var front_pivots: Array[Node3D]
@export var _wheel_radium := 1.0

func update_wheels(delta: float, path: Path3D, follow: PathFollow3D, speed: float) -> void:
	var angular_speed := speed / _wheel_radium
	for wheel in wheels:
		wheel.rotate_x(angular_speed * delta)
	
	var future_transform := path.curve.sample_baked_with_rotation(follow.progress + 3)
	var dir := -future_transform.basis.z
	var angle_y := atan2(dir.x, dir.z)
	for pivot in front_pivots:
		pivot.global_rotation.y = angle_y

func randomize_color() -> void:
	randomize()
	var color = Color(randf(), randf(), randf())
	var mat = get_surface_override_material(1).duplicate()
	mat.albedo_color = color
	set_surface_override_material(1, mat)
