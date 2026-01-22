extends Node3D
class_name CarController

### PATH & CURVE FOLLOWING ###
@onready var _path_follow: PathFollow3D = get_parent()
@export var _triggers_on_curve: Array[Area3D]
var _triggers_on_curve_offsets: Array[float]
@onready var _path: Path3D = _path_follow.get_parent()
@onready var down_ray = $Raycasts/RayCast3DDown
@onready var up_ray = $Raycasts/RayCast3DUp
var y_offset = 1

### MOVEMENT ###
@export var _max_speed: float
@export var _slow_speed: float
@export var _acceleration: float
@export var _decceleration : float
var _current_speed: float = 0
var _target_speed: float = 0
var _nb_close_obstacle: int = 0
var _nb_front_obstacle: int = 0
var _nb_far_obstacle: int = 0
var _must_stop = false
var _should_stop = false
var _should_be_slow = false

###Nodes###
@export var car_audio: CarAudio
@export var car_visuals: CarVisuals


# Store the original Z offsets of the triggers before resetting their positions.
func _ready():
	car_visuals.randomize_color()
	for i in _triggers_on_curve.size():
		var offset = _triggers_on_curve[i].position.z
		_triggers_on_curve_offsets.append(offset)
		_triggers_on_curve[i].position = Vector3(0,0,0)

func _process(delta: float) -> void:
	car_audio.update_audio(_current_speed, _max_speed)
	car_visuals.update_wheels(delta, _path, _path_follow, _current_speed)
	
	if _must_stop:
		_current_speed = 0
		return
		
	_target_speed = (
		0.0 if _should_stop
		else _slow_speed if _should_be_slow
		else _max_speed
	)

	if (_current_speed > _target_speed):
		_current_speed = move_toward(_current_speed, _target_speed, delta * _decceleration)
	else:
		_current_speed = move_toward(_current_speed, _target_speed, delta * _acceleration)

	_car_progress(delta)
	
func _car_progress(delta: float) -> void:
	if _path_follow.progress < 0.2:
		position.y = 0
	else:
		_car_transform_correction()
		position.y -= y_offset
	_path_follow.progress += _current_speed * delta

	for i in _triggers_on_curve.size():
		var offset_progress = _path_follow.progress + _triggers_on_curve_offsets[i] + _current_speed / 2
		var position_on_curve = _path.curve.sample_baked(offset_progress)
		var car_global_position = position_on_curve + _path.position
		_triggers_on_curve[i].global_transform.origin = car_global_position
		
func _car_transform_correction() -> void:
	var collision_point: Vector3
	var collision_normal: Vector3

	if down_ray.is_colliding():
		collision_point = down_ray.get_collision_point()
		collision_normal = down_ray.get_collision_normal()
	elif up_ray.is_colliding():
		collision_point = up_ray.get_collision_point()
		collision_normal = up_ray.get_collision_normal()
	else:
		y_offset = 0
		return

	var offset = (global_position - collision_point).y
	y_offset = offset
		
func _on_close_trigger_area_entered(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_close_obstacle += 1
	if _nb_close_obstacle>0:
		_must_stop = true

func _on_close_trigger_area_exited(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_close_obstacle -= 1
	if _nb_close_obstacle == 0:
		_must_stop = false
	elif _nb_close_obstacle < 0:
		printerr("_nb_obstacle negative.")
		_nb_close_obstacle = 0
		
func _on_front_trigger_area_entered(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_front_obstacle += 1
	if _nb_front_obstacle > 0:
		_should_stop = true

func _on_front_trigger_area_exited(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_front_obstacle -= 1
	if _nb_front_obstacle == 0:
		_should_stop = false
	elif _nb_front_obstacle < 0:
		printerr("_nb_front_obstacle negative.")
		_nb_front_obstacle = 0

func _on_far_trigger_area_entered(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_far_obstacle += 1
	if _nb_far_obstacle > 0:
		_should_be_slow = true

func _on_far_trigger_area_exited(area: Area3D) -> void:
	if self.is_ancestor_of(area):
		return
	_nb_far_obstacle -= 1
	if _nb_far_obstacle == 0:
		_should_be_slow = false
	elif _nb_far_obstacle < 0:
		printerr("nb_far_obstacle negative.")
		_nb_far_obstacle = 0
