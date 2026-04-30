extends Node2D

func _process(_delta: float) -> void:
	# Should we quit
	if not Config.get_value("overlays.biofeedback_push_frequency.enabled"):
		queue_free()
