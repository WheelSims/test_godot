extends Node3D

### PATH & CURVE FOLLOWING ###
@onready var path_follow: PathFollow3D = get_parent()
@export var triggers_on_curve: Array[Area3D]
var triggers_on_curve_offsets: Array[float]
@onready var path: Path3D = path_follow.get_parent()

### AUDIO ###
@onready var motor_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D

### MOVEMENT ###
@export var max_speed: float
@export var acceleration: float
var current_speed: float = 0
var target_speed: float = 0
var nb_obstacle: int = 0

### WHEELS ###
var wheel_radium: float = 1.0
@export var wheels: Array[MeshInstance3D]
@export var front_pivots: Array[Node3D]
var wheels_angular_speed: float = 0.0

# Store the original Z offsets of the triggers before resetting their positions.
func _ready():
	for i in triggers_on_curve.size():
		var offset = triggers_on_curve[i].position.z
		triggers_on_curve_offsets.append(offset)
		triggers_on_curve[i].position = Vector3(0,0,0)

func _process(delta: float) -> void:
	car_audio()
	wheel_movements(delta)
		
	if (nb_obstacle < 1):
		target_speed = max_speed
		current_speed = move_toward(current_speed, target_speed, delta * acceleration)
		carprogress(delta)
	else:
		current_speed = 0

func carprogress(delta: float) -> void:
	path_follow.progress += current_speed * delta
	for i in triggers_on_curve.size():
		var offset_progress = path_follow.progress + triggers_on_curve_offsets[i]
		var position_on_curve = path.curve.sample_baked(offset_progress)
		var global_position = position_on_curve + path.position
		triggers_on_curve[i].global_transform.origin = global_position
		
func car_audio() -> void:
	motor_sound.pitch_scale = lerpf(1, 1.5, current_speed/max_speed)

func wheel_movements(delta: float) -> void:
	#Wheels rotation on x
	wheels_angular_speed = current_speed / wheel_radium
	for wheel in wheels:
		wheel.rotate_x(wheels_angular_speed * delta)
	
	#Front Wheels rotation on y
	var curve_transform_on_front_wheels = path.curve.sample_baked_with_rotation(path_follow.progress + 3)
	var frontwheeldirection = -curve_transform_on_front_wheels.basis.z
	var angle_y = atan2(frontwheeldirection.x, frontwheeldirection.z)
	var desired_rotation = Vector3(0, angle_y, 0)
	for front_pivot in front_pivots:
		front_pivot.global_rotation = desired_rotation

func _on_front_trigger_area_entered(area: Area3D) -> void:
	if ((area.is_in_group("NPC") or area.is_in_group("Player")) and not self.is_ancestor_of(area)):
		nb_obstacle += 1

func _on_front_trigger_area_exited(area: Area3D) -> void:
	if ((area.is_in_group("NPC") or area.is_in_group("Player")) and not self.is_ancestor_of(area)):
		nb_obstacle -= 1
