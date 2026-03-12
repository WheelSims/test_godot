extends Control

@onready var main: Node = get_tree().get_root().get_node("main")
@export var label: Label

var _fps: float = 120.0

func _process(delta):
	var text: String = ""
	
	# Player information
	if main.player:
		text += str(main.player.get_linear_speed()) + " m/s\n"
	else:
		text += "No player loaded.\n"
	
	# FPS information
	var fps = 1/delta
	_fps = 0.99 * _fps + 0.01 * 1/delta  # Rolling average on 100 samples
	text += "Current FPS: %0.0f FPS\n" % _fps
	
	label.text = text
	
	
	# Should we quit
	if not main.config.get_value("overlays.debug.enabled"):
		queue_free()
