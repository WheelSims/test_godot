# TimeTrial.gd
class_name TimeTrial
extends Race

var distance_target: float

func _init(_distance_target: float, _player: RigidBody3D):
	distance_target = _distance_target
	super._init(_player)	

func update(delta: float):
	super.update(delta)

func is_finished() -> bool:
	return current_distance >= distance_target
