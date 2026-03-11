extends Node

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------
@onready var main: Node = get_tree().get_root().get_node("main")

# -------------------------------------------------------------------
# Private
# -------------------------------------------------------------------
var _current_screens_node: Node


func load_windows():
	# TODO add secondary screen
	# Load the window(s)
	_current_screens_node = load("res://devices/screens/single_screen.tscn").instantiate()
	add_child(_current_screens_node)
	
	# Assign the game viewport to this/these window(s)
	main.main_window = _current_screens_node.get_node("main_window")
	_current_screens_node.get_node("main_window/texture_rect").texture = main.scene_viewport.get_texture()
	
	main.load_overlays()
	
func unload_windows():
	if _current_screens_node:
		_current_screens_node.queue_free()
