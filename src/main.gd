extends Node

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

## The viewport the 3D scene is rendered in.
@onready var scene_viewport: SubViewport = get_node("scene_viewport")

## The simulator configuration.
@onready var config: Node = get_node("config")

## The player, automatically updated on scene change.
var player: Node3D = null


## (private) Store the current scene.
var _current_scene_node: Node3D = null


# -------------------------------------------------------------------
# Ready
# -------------------------------------------------------------------

func _ready():
	config.load_config()
	config._save_config()  # In case there was no config originally
	
	# Load at least the main window
	$screens.load_windows()
	
	# Apply config
	for key in config.get_keys():
		config_value_changed(key)

# -------------------------------------------------------------------
# Scene loading/unloading
# -------------------------------------------------------------------

## Load scene and update player reference.
func load_scene(path: String):
	# Unload current scene first (to be sure)
	unload_scene()
	# Load the scene
	_current_scene_node = load(path).instantiate()
	scene_viewport.add_child(_current_scene_node)	
	# Update the player reference
	player = _current_scene_node.get_node("player")

## Unload scene and update player reference.
func unload_scene():
	if _current_scene_node:
		_current_scene_node.queue_free()
	player = null

# -------------------------------------------------------------------
# Overlay loading/unloading
# -------------------------------------------------------------------

## Load overlay
func load_overlay(overlay_name: String):
	var node = load("res://overlays/" + overlay_name + ".tscn").instantiate()
	$scene_viewport.add_child(node)

# -------------------------------------------------------------------
# Updated config value
# -------------------------------------------------------------------

## Called by config when modified, mainly to instanciate new modules.
func config_value_changed(key):
	match(key):
		"overlays.speed_indicator.enabled":
			if config.get_value("overlays.speed_indicator.enabled"):
				load_overlay("speed_indicator")
		"overlays.debug.enabled":
			if config.get_value("overlays.debug.enabled"):
				load_overlay("debug")
		"devices.screens.floor.enabled":
			$screens.unload_windows()
			$screens.load_windows()
