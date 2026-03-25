## This script manages the simulator configuration and saves values that are different from defaults
## on the local filesystem. Configuration values are accessed using get_value or set_value, and are
## stored using a string identifier (e.g. "d_box.enabled"). Local saving is done automatically on
## set_value.
extends Node
@onready var main: Node = get_tree().get_root().get_node("main")

# -------------------------------------------------------------------
# Private variables and functions
# -------------------------------------------------------------------
var _CONFIG_FILENAME = "user://config.json"

## Defaults (use default=null for headers)
var _defaults: Dictionary[String, Dictionary] = {
	"player": {"order": 1, "label": "SIMULATED PARAMETERS"},
	"player.mass": {"order": 1.01, "label": "User+wheelchair mass", "unit": "kg", "type": "float", "default": 70.0, "min": 10.0, "max": 300.0},
	"player.camera.fov": {"order": 1.02, "label": "Field of view", "unit": "deg", "type": "float", "default": 75.0, "min": 40.0, "max": 150.0},
	"player.camera.angle": {"order": 1.03, "label": "Camera angle", "unit": "deg", "type": "float", "default": 0.0, "min": -45.0, "max": 45.0},

	"overlays": {"order": 2, "label": "OVERLAYS"},
	"overlays.speed_indicator.enabled": {"order": 2.01, "label": "Speed indicator", "type": "bool", "default": true},
	"overlays.debug.enabled": {"order": 2.02, "label": "Debug", "type": "bool", "default": false},

	"devices": {"order": 3, "label": "DEVICE SETTINGS"},

	"devices.screens": {"order": 3.1, "label": "Screens"},

	"devices.screens.single_screen": {"order": 3.2, "label": "Single screen"},
	"devices.screens.single_screen.enabled": {"order": 3.21, "label": "Enabled", "type": "bool", "default": true},
	"devices.screens.single_screen.full_screen.enabled": {"order": 3.22, "label": "Full screen", "type": "bool", "default": true},
	"devices.screens.single_screen.full_screen.screen_index": {"order": 3.23, "label": "Front screen number", "type": "int", "default": 1, "min": 1, "max": 5},

	"devices.screens.front_floor_screens": {"order": 3.3, "label": "Front+floor screens"},
	"devices.screens.front_floor_screens.enabled": {"order": 3.31, "label": "Enabled", "type": "bool","default": false},
	"devices.screens.front_floor_screens.full_screen.enabled": {"order": 3.32, "label": "Full screen", "type": "bool", "default": true},
	"devices.screens.front_floor_screens.full_screen.front_screen_index": {"order": 3.33, "label": "Front screen number", "type": "int", "default": 2, "min": 1, "max": 5},
	"devices.screens.front_floor_screens.full_screen.floor_screen_index": {"order": 3.34, "label": "Floor screen number", "type": "int", "default": 3, "min": 1, "max": 5},

	"devices.others": {"order": 3.4, "label": "Other devices"},
	"devices.d_box.enabled": {"order": 3.5, "label": "D-Box", "type": "bool", "default": false},
	"devices.motorized_rollers.enabled": {"order": 3.6, "label": "Motorized rollers", "type": "bool", "default": false},
}

## Overrides
var _contents: Dictionary[String, Variant] = {}

## Update monitoring
var _modified: Dictionary[String, Variant] = {}

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

func _custom_compare(key1, key2):
	return _defaults[key1].order < _defaults[key2].order

func get_keys():
	var keys = _defaults.keys()
	keys.sort_custom(_custom_compare)
	return keys

## Get config label
func get_label(key: String):
	return _defaults[key]["label"]

## Get config unit
func get_unit(key: String):
	if "unit" in _defaults[key]:
		return _defaults[key]["unit"]
	else:
		return ""

## Get config type
func get_type(key: String):
	if "type" in _defaults[key]:
		return _defaults[key]["type"]
	else:
		return null

## Get config value
func get_value(key: String):
	if key in _contents:
		return _contents[key]
	elif (key in _defaults) and ("default" in _defaults[key]):
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
	# Tell everyone that config has been modified
	for caller_id in _modified:
		_modified[caller_id][key] = true

## Has value been changed since last call with a given caller_id?
## Returns true if the value has been changed since last call. The caller_id is used so that two
## scripts can ask if a same value has been changed and they both will receive a true value on their
## first call, and false on their subsequent calls until it has been changed again.
func value_changed(caller_id: String, key: String):
	if caller_id not in _modified:
		_modified[caller_id] = {key: false}
		return true
		
	if key not in _modified[caller_id]:
		_modified[caller_id][key] = false
		return true
	
	var value = _modified[caller_id][key]
	_modified[caller_id][key] = false
	return value
