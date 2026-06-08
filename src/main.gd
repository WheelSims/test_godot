extends Node

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------

## The viewport the 3D scene is rendered in.
@onready var scene_viewport: SubViewport = get_node("SceneViewport")

## The different overlays that can be loaded dynamically based on configuration options
@export var available_overlays: Dictionary[String, PackedScene]

## The different devices that can be loaded dynamically based on configuration options
@export var available_devices: Dictionary[String, PackedScene]


## (private) Store the current scene.
var _current_scene_node: Node3D = null


# -------------------------------------------------------------------
# Scene loading/unloading
# -------------------------------------------------------------------

## Load scene
func load_scene(path: String):
	# Unload current scene first (to be sure)
	unload_scene()
	# Load the scene
	_current_scene_node = load(path).instantiate()
	scene_viewport.add_child(_current_scene_node)	
	
	SignalBus.session_scene.emit(path)

## Unload scene
func unload_scene():
	if _current_scene_node:
		_current_scene_node.queue_free()

# -------------------------------------------------------------------
# Updated config value
# -------------------------------------------------------------------

## Called by config when modified, mainly to instanciate new modules.
func _process(_delta):
	for key in available_overlays:
		if Config.value_changed("main", key) and Config.get_value(key):
			scene_viewport.add_child(available_overlays[key].instantiate())
	for key in available_devices:
		if Config.value_changed("main", key) and Config.get_value(key):
			add_child(available_devices[key].instantiate())
