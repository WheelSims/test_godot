# DistanceChallenge.gd
class_name DistanceChallenge
extends Race

var time_limit: float = 60.0
var timer: float = 0.0

func _init(_time_limit: float):
	time_limit = _time_limit
	
func start():
	timer = 0.0

func update(delta: float, _traveled_distance: float):
	timer += delta

func is_finished() -> bool:
	return timer >= time_limit
