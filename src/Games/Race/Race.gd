# Race.gd
class_name Race
extends Resource  # ou Object, ou même Node si tu veux

func start():
	pass  # à redéfinir

func update(delta: float, _traveled_distance: float):
	pass

func is_finished() -> bool:
	return false
