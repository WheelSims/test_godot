extends Node

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

## The viewport the 3D scene is rendered in.
@onready var scene_viewport: SubViewport = get_node("scene_viewport")

## The simulator configuration.
@onready var config: Node = get_node("config")

## The player.
var player: Node3D = null

## (private) Store the current scene.
var _current_scene_node: Node3D = null


# -------------------------------------------------------------------
# Ready
# -------------------------------------------------------------------

func _ready():
	config.load_config()
	config._save_config()  # In case there was no config originally
	# Apply config
	for key in config.get_keys():
		config_value_changed(key)

# -------------------------------------------------------------------
# Scene loading/unloading
# -------------------------------------------------------------------

## Load scene.
func load_scene(path: String):
	# Unload current scene first (to be sure)
	unload_scene()
	
	# Load the scene
	_current_scene_node = load(path).instantiate()
	scene_viewport.add_child(_current_scene_node)
	
	# Update the player reference and mass
	player = _current_scene_node.get_node("player")
	player.mass = config.get_value("player.mass")

## Unload scene.
func unload_scene():
	if _current_scene_node:
		_current_scene_node.queue_free()
	player = null

# -------------------------------------------------------------------
# Updated config value
# -------------------------------------------------------------------

## Propagate config value changes to their corresponding modules
func config_value_changed(key):
	match(key):
		"player.mass":
			if player:
				player.mass = config.get_value(player.mass)
		"devices.screens.floor.enabled":
			$screens.unload_windows()
			$screens.load_windows()
