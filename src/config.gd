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
	"player.mass": {"order": 1, "label": "User+wheelchair mass", "unit": "kg", "default": 70.0},
	"overlays": {"order": 2, "label": "OVERLAYS", "unit": "", "default": null},
	"overlays.speed_indicator.enabled": {"order": 3, "label": "Speed indicator", "unit": "", "default": true},
	"overlays.debug.enabled": {"order": 4, "label": "Debug", "unit": "", "default": false},
	"devices": {"order": 5, "label": "DEVICE SETTINGS", "unit": "", "default": null},
	"devices.screens": {"order": 6, "label": "Screens", "unit": "", "default": null},
	"devices.screens.floor.enabled": {"order": 7, "label": "Floor projection", "unit": "", "default": false},
	"devices.others": {"order": 8, "label": "Other devices", "unit": "", "default": null},
	"devices.d_box.enabled": {"order": 9, "label": "D-Box", "unit": "", "default": false},
	"devices.motorized_rollers.enabled": {"order": 10, "label": "Motorized rollers", "unit": "", "default": false},
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
func get_keys():
	var output = []
	for key in _defaults:  # prealloc
		output.append("")
	for key in _defaults:  # order
		output[_defaults[key]["order"]] = key
	return output

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

## Set config value
func set_value(key: String, value):
	if value == _defaults[key]["default"]:
		_contents.erase(key)
	else:
		_contents[key] = value
	_save_config()
	# Tell the main script that a value has been changed
	main.config_value_changed(key)
