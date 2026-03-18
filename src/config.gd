## This script manages the simulator configuration and saves values that are different from defaults
## on the local filesystem. Configuration values are accessed using get_value or set_value, and are
## stored using a string identifier (e.g. "d_box.enabled"). Local saving is done automatically on
## set_value.
extends Node

# -------------------------------------------------------------------
# References
# -------------------------------------------------------------------
@onready var main: Node = get_tree().get_root().get_node("main")

# -------------------------------------------------------------------
# Private variables and functions
# -------------------------------------------------------------------
var _CONFIG_FILENAME = "user://config.json"

## Defaults (use default=null for headers)
var _defaults: Dictionary[String, Dictionary] = {
	"player": {"order": 0, "label": "SIMULATED PARAMETERS", "unit": "", "default": null},
	"player.mass": {"order": 1, "label": "User+wheelchair mass", "unit": "kg", "default": 70.0, "min": 10.0, "max": 300.0},
	"player.camera.fov": {"order": 2, "label": "Field of view", "unit": "deg", "default": 75.0, "min": 40.0, "max": 150.0},
	"player.camera.angle": {"order": 3, "label": "Camera angle", "unit": "deg", "default": 0.0, "min": -45.0, "max": 45.0},
	"overlays": {"order": 10, "label": "OVERLAYS", "unit": "", "default": null},
	"overlays.speed_indicator.enabled": {"order": 11, "label": "Speed indicator", "unit": "", "default": true},
	"overlays.debug.enabled": {"order": 12, "label": "Debug", "unit": "", "default": false},
	"devices": {"order": 20, "label": "DEVICE SETTINGS", "unit": "", "default": null},
	"devices.screens": {"order": 30, "label": "Screens", "unit": "", "default": null},
	"devices.screens.single_screen.enabled": {"order": 31, "label": "Single screen", "unit": "", "default": true},
	"devices.screens.front_floor_screens.enabled": {"order": 32, "label": "Front and floor screen", "unit": "", "default": false},
	"devices.others": {"order": 40, "label": "Other devices", "unit": "", "default": null},
	"devices.d_box.enabled": {"order": 41, "label": "D-Box", "unit": "", "default": false},
	"devices.motorized_rollers.enabled": {"order": 42, "label": "Motorized rollers", "unit": "", "default": false},
}

## Overrides
var _contents: Dictionary[String, Variant] = {}

## Save current configuration to local filesystem (automatic on set_value)
func _save_config():
	var file := FileAccess.open(_CONFIG_FILENAME, FileAccess.WRITE)
	file.store_string(JSON.stringify(_contents, "\t"))
	file.close()

# -------------------------------------------------------------------
# Public variables and functions
# -------------------------------------------------------------------

## Load configuration from local system
func load_config():
	if not FileAccess.file_exists(_CONFIG_FILENAME):
		return
	
	var file := FileAccess.open(_CONFIG_FILENAME, FileAccess.READ)
	var parsed_v: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	
	for item in parsed_v:
		_contents[item] = parsed_v[item]

## Get ordered keys

func custom_compare(key1, key2):
	return _defaults[key1].order < _defaults[key2].order

func get_keys():
	var keys = _defaults.keys()
	keys.sort_custom(custom_compare)
	return keys

## Get config label
func get_label(key: String):
	return _defaults[key]["label"]

## Get config unit
func get_unit(key: String):
	return _defaults[key]["unit"]

## Get config value
func get_value(key: String):
	if key in _contents:
		return _contents[key]
	elif key in _defaults:
		return _defaults[key]["default"]
	else:
		return null

## Get config min value or null if not existing
func get_min_value(key: String):
	if key in _defaults and "min" in _defaults[key]:
		return _defaults[key]["min"]
	else:
		return null

## Get config min value or null if not existing
func get_max_value(key: String):
	if key in _defaults and "max" in _defaults[key]:
		return _defaults[key]["max"]
	else:
		return null

## Set config value
func set_value(key: String, value):
	if value == _defaults[key]["default"]:
		_contents.erase(key)
	else:
		_contents[key] = value
	_save_config()
	# Tell the main script that a value has been changed
	main.config_value_changed(key)
