# TimeTrial.gd
class_name TimeTrial
extends Race

var distance_target: float
var current_distance: float = 0.0

func _init(_distance_target: float):
	distance_target = _distance_target
	
func start():
	current_distance = 0.0

func update(delta: float, _traveled_distance: float):
	current_distance = _traveled_distance

func is_finished() -> bool:
	return current_distance >= distance_target
