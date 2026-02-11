# DistanceChallenge.gd
class_name DistanceChallenge
extends Race

var time_limit: float = 60.0

func _init(_time_limit: float, _player: RigidBody3D):
	time_limit = _time_limit
	super._init(_player)

func update(delta: float):
	super.update(delta)

func is_finished() -> bool:
	return timer >= time_limit
