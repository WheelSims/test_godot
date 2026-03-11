extends Node

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------
@onready var main: Node = get_tree().get_root().get_node("main")
@onready var config: Node = main.get_node("config")


# -------------------------------------------------------------------
# Private
# -------------------------------------------------------------------
var _current_screens_node: Node


func load_windows():
	if config.get_value("devices.screens.floor.enabled"):
		pass
	
	else:  # Only one screen
		# Load the window(s)
		_current_screens_node = load("res://devices/screens/single_screen.tscn").instantiate()
		add_child(_current_screens_node)
		
		# Assign the game viewport to this/these window(s)
		_current_screens_node.get_node("front_window/texture_rect").texture = main.scene_viewport.get_texture()
	
	
func unload_windows():
	if _current_screens_node:
		_current_screens_node.queue_free()
