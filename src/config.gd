## This script manages the simulator configuration and saves values that are different from defaults
## on the local filesystem. Configuration values are accessed using get_value or set_value using a
## string identifier (e.g. "devices.d_box.enabled"). Local saving is done automatically on
## set_value.
##
## This script is autoloaded so that we can access the configuration options from any script, e.g.:
## - Config.get_value(config_id)
## - Config.value_changed(requester_id, config_id)
##
## The configuration panel of the GUI is generated automatically based on the _defaults dictionary,
## and user modifications to the configuration panel calls its corresponding set_value.
extends Node

# -------------------------------------------------------------------
# Private variables and functions
# -------------------------------------------------------------------
var _CONFIG_FILENAME = "user://config.json"

## Defaults (use default=null for headers)
var _defaults: Dictionary[String, Dictionary] = {
	"player": {"order": 1, "label": "SIMULATED PARAMETERS"},
	"player.mass":
	{
		"order": 1.01,
		"label": "User+wheelchair mass",
		"unit": "kg",
		"type": "float",
		"default": 70.0,
		"min": 10.0,
		"max": 300.0
	},
	"player.wheel_diameter":
	{
		"order": 1.02,
		"label": "Wheel diameter",
		"unit": "m",
		"type": "float",
		"default": 0.62,
		"min": 0.40,
		"max": 0.80
	},
	"player.pushrim_diameter":
	{
		"order": 1.03,
		"label": "Pushrim diameter",
		"unit": "m",
		"type": "float",
		"default": 0.54,
		"min": 0.40,
		"max": 0.80
	},
	"player.camera.fov":
	{
		"order": 1.04,
		"label": "Field of view",
		"unit": "deg",
		"type": "float",
		"default": 75.0,
		"min": 40.0,
		"max": 150.0
	},
	"player.camera.angle":
	{
		"order": 1.05,
		"label": "Camera angle",
		"unit": "deg",
		"type": "float",
		"default": 0.0,
		"min": -45.0,
		"max": 45.0
	},
	"game": {"order": 2, "label": "GAME PARAMETERS"},
	"game.racing.type":
	{
		"order": 2.1,
		"label": "Type of challenge",
		"type": "options",
		"items": ["Fastest time in a given distance", "Longest distance in a given time"],
		"default": 0
	},
	"game.racing.distance":
	{
		"order": 2.2,
		"label": "Distance (for fastest time)",
		"unit": "m",
		"type": "int",
		"default": 100,
		"min": 20,
		"max": 1000
	},
	"game.racing.time":
	{
		"order": 2.3,
		"label": "Time (for longest distance)",
		"unit": "s",
		"type": "int",
		"default": 60,
		"min": 10,
		"max": 360
	},
	"overlays": {"order": 3, "label": "OVERLAYS"},
	"overlays.speed_indicator.enabled":
	{"order": 3.01, "label": "Speed indicator", "type": "bool", "default": true},
	"overlays.debug.enabled": {"order": 3.02, "label": "Debug", "type": "bool", "default": false},
	"overlays.biofeedback_push_pattern.enabled":
	{"order": 3.03, "label": "Biofeedback Push pattern", "type": "bool", "default": false},
	"overlays.contact_angle_start":
	{
		"order": 3.04,
		"label": "Contact angle start",
		"unit": "deg",
		"type": "float",
		"default": -55.0,
		"min": -65.0,
		"max": 20.0
	},
	"overlays.contact_angle_end":
	{
		"order": 3.05,
		"label": "Contact angle end",
		"unit": "deg",
		"type": "float",
		"default": 55.0,
		"min": 20.0,
		"max": 140.0
	},
	"overlays.biofeedback_push_frequency.enabled":
	{"order": 3.06, "label": "Biofeedback Push Frequency", "type": "bool", "default": false},
	"devices": {"order": 4, "label": "DEVICE SETTINGS"},
	"devices.screens": {"order": 4.1, "label": "Screens"},
	"devices.screens.single_screen": {"order": 4.2, "label": "Single screen"},
	"devices.screens.single_screen.enabled":
	{"order": 4.21, "label": "Enabled", "type": "bool", "default": true},
	"devices.screens.single_screen.full_screen.enabled":
	{"order": 4.22, "label": "Full screen", "type": "bool", "default": true},
	"devices.screens.single_screen.full_screen.screen_index":
	{
		"order": 4.23,
		"label": "Front screen number",
		"type": "int",
		"default": 1,
		"min": 1,
		"max": 5
	},
	"devices.screens.front_floor_screens": {"order": 4.3, "label": "Front+floor screens"},
	"devices.screens.front_floor_screens.enabled":
	{"order": 4.31, "label": "Enabled", "type": "bool", "default": false},
	"devices.screens.front_floor_screens.full_screen.enabled":
	{"order": 4.32, "label": "Full screen", "type": "bool", "default": true},
	"devices.screens.front_floor_screens.full_screen.front_screen_index":
	{
		"order": 4.33,
		"label": "Front screen number",
		"type": "int",
		"default": 2,
		"min": 1,
		"max": 5
	},
	"devices.screens.front_floor_screens.full_screen.floor_screen_index":
	{
		"order": 4.34,
		"label": "Floor screen number",
		"type": "int",
		"default": 3,
		"min": 1,
		"max": 5
	},
	"devices.others": {"order": 4.4, "label": "Other devices"},
	"devices.d_box.enabled": {"order": 4.5, "label": "D-Box", "type": "bool", "default": false},
	"devices.motorized_rollers.enabled":
	{"order": 4.6, "label": "Motorized rollers", "type": "bool", "default": false},
	"devices.optitrack.enabled":
	{"order": 4.7, "label": "Optitrack", "type": "bool", "default": false},
	"devices.python_bridge.enabled":
	{"order": 4.8, "label": "Python Bridge", "type": "bool", "default": false},
	"devices.python_bridge.python_path":
	{"order": 4.81, "label": "Python app path", "type": "file", "default": ""},
	"devices.python_bridge.script_path":
	{"order": 4.82, "label": "Python script path", "type": "file", "default": ""},
	"coordinates.left_wheel_center":
	{
		"order": 5.01,
		"label": "Left wheel center",
		"type": "array",
		"default": [-0.2, 0.3, -0.75],
		"reference": "simulator"
	},
	"coordinates.right_wheel_center":
	{
		"order": 5.02,
		"label": "Right wheel center",
		"type": "array",
		"default": [-0.2, 0.3, -0.2],
		"reference": "simulator"
	},
	"coordinates.left_hand":
	{
		"order": 5.03,
		"label": "Left hand",
		"type": "array",
		"default": [0.0, 0.0, 0.0],
		"reference": "forearm_cluster_left"
	},
	"coordinates.right_hand":
	{
		"order": 5.04,
		"label": "Right hand",
		"type": "array",
		"default": [0.0, 0.0, 0.0],
		"reference": "forearm_cluster_right"
	},
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
# Instantiating
# -------------------------------------------------------------------
func _ready():
	load_config()
	_save_config()  # In case there was no configuration file yet


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


## Get config max value or null if not existing
func get_max_value(key: String):
	if key in _defaults and "max" in _defaults[key]:
		return _defaults[key]["max"]
	else:
		return null


## Get config step value or 1.0 if not existing
func get_step_value(key: String):
	if key in _defaults and "step" in _defaults[key]:
		return _defaults[key]["step"]
	else:
		return 1.0


## Get items or null if not existing
func get_items(key: String):
	if key in _defaults and "items" in _defaults[key]:
		return _defaults[key]["items"]
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
