extends Control

@onready var main: Node = get_tree().get_root().get_node("main")
@export var label: Label

var _fps: float = 120.0

func _process(delta):
	var text: String = ""
	
	# Player information
	if main.player:
		text += "%0.2f m/s\n" % main.player.get_linear_speed()
	else:
		text += "No player loaded.\n"
	
	# FPS information
	var fps = 1/delta
	_fps = 0.99 * _fps + 0.01 * 1/delta  # Rolling average on 100 samples
	text += "Current FPS: %0.0f FPS\n" % _fps
	
	# Check if any device has something to tell
	for node in main.get_children():
		text += "Node %s: " % node.name
		if "get_debug_text" in node:
			text += node.get_debug_text()
		text += "\n"
	
	label.text = text
	
	
	# Should we quit
	if not main.config.get_value("overlays.debug.enabled"):
		queue_free()
