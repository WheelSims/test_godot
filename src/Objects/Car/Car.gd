extends Node3D

@onready var pathFollow: PathFollow3D = get_parent()
@onready var motor_sound = $AudioStreamPlayer3D
@export var triggers_on_curve: Array[Area3D]
var triggers_on_curve_offsets: Array[float]
@export var max_speed: float
@export var acceleration: float
var nb_obstacle: float = 0
var current_speed : float = 0
var target_speed : float

# Store the original Z offsets of the triggers before resetting their positions.
func _ready():
	for i in triggers_on_curve.size():
		var offset = triggers_on_curve[i].position.z
		triggers_on_curve_offsets.append(offset)
		triggers_on_curve[i].position = Vector3(0,0,0)

func _process(delta: float) -> void:
	if (nb_obstacle < 1):
		target_speed = max_speed
		current_speed = move_toward(current_speed, target_speed, delta * acceleration)
		carprogress(delta)

func carprogress(delta: float) -> void:
	pathFollow.progress += current_speed * delta
	for i in triggers_on_curve.size():
		var offset_progress = pathFollow.progress + triggers_on_curve_offsets[i]
		var position_on_curve = pathFollow.get_parent().curve.sample_baked(offset_progress)
		var global_position = position_on_curve + pathFollow.get_parent().position
		triggers_on_curve[i].global_transform.origin = global_position
		
func carAudio() -> void:
	motor_sound.pitch_scale = lerp(1, 2, current_speed/max_speed)
	

func _on_front_trigger_area_entered(area: Area3D) -> void:
	if (area.is_in_group("NPC") and not self.is_ancestor_of(area)):
		nb_obstacle += 1

func _on_front_trigger_area_exited(area: Area3D) -> void:
	if (area.is_in_group("NPC") and not self.is_ancestor_of(area)):
		nb_obstacle -= 1
