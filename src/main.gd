extends Node

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------
@onready var _scene_viewport: SubViewport = get_node("scene_viewport")

## Store the current scene.
var _current_scene_node: Node3D = null

## Store the current screen configuration.
var _current_screens_node: Node2D = null

## Load scene.
func load_scene(path: String):
	# Load the scene
	_current_scene_node = load(path).instantiate()
	_scene_viewport.add_child(_current_scene_node)
	
	# Load the window(s)
	# TODO Dual-window and config
	_current_screens_node = load("res://devices/screens/single_screen.tscn").instantiate()
	add_child(_current_screens_node)
	
	# Assign the game viewport to this/these window(s)
	_current_screens_node.get_node("front_window/texture_rect").texture = _scene_viewport.get_texture()


	
## Unload scene.
func unload_scene():
	if _current_scene_node:
		_current_scene_node.queue_free()
	if _current_screens_node:
		_current_screens_node.queue_free()
