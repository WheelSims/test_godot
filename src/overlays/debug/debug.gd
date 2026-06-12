## This overlay prints debugging information on the screen. This works by going through every
## device node that have been loaded dynamically and checking if they have a "get_debug_text()"
## function. If they have such function, then it is called and the returned text is added to the
## debug overlay.
extends Control

@export var label: Label

var _fps: float = 120.0


func _process(delta):
	var text: String = ""

	# Player information
	if Globals.player:
		text += "%0.2f m/s\n" % Globals.player.get_linear_speed()
	else:
		text += "No player loaded.\n"

	# FPS information
	_fps = 0.9 * _fps + 0.1 * 1 / delta  # Rolling average on 10 samples
	text += "Current FPS: %0.0f FPS\n" % _fps

	# Check if any device has something to tell
	for node in Globals.main.get_children():
		if "get_debug_text" in node:
			text += "Node %s: " % node.name
			text += node.get_debug_text()
			text += "\n"

	label.text = text

	# Should we quit
	if not Config.get_value("overlays.debug.enabled"):
		queue_free()
