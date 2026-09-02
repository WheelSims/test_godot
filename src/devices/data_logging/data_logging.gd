## This script receives information from SignalBus and sends it outward through the python_bridge
extends Node2D

# variable to hold signal received from main.gd are initiated with nulls
var scenes = {"current": "", "new": ""}

# variable to hold signals received from player.gd are initiated with nulls
var player_trajectory = {"position": NAN, "rotation": NAN}

# variable to hold signals pertaining to toggling on/off of data_logging
var logging = {"past": false, "current": false}

# Set up the dictionary to save data in
var data = {}

# whether or not connection to python was established
var connected = false
var connection_command = NAN


# called everytime a signal is received from main.gd to save it
func _scene_signal_received(scene_name):
	scenes["new"] = scene_name.get_file().split(".")[0].replace("_", "")
	# When logging in on, update current scene if new
	if scenes["current"] != scenes["new"]:
		# If a trial was in progress (i.e. previous scene is not blank), end it
		if scenes["current"] != "":
			if logging["current"] == true and Globals.main.has_node("PythonBridge"):
				Globals.main.get_node("PythonBridge").run("end_trial", data)
			player_trajectory["position"] = NAN
			player_trajectory["rotation"] = NAN

		scenes["current"] = scenes["new"]
		update_data()

		# If new trial is not empty, create one
		if (
			logging["current"] == true
			and scene_name != ""
			and Globals.main.has_node("PythonBridge")
		):
			Globals.main.get_node("PythonBridge").run("create_trial", data)


# called everytime a signal is received from player.gd to save it
func _player_signal_received(pos, rot):
	player_trajectory["position"] = pos
	player_trajectory["rotation"] = rot


# called when a signal is received from python_bridge.gd
func _python_signal_received(connection):
	if connected != connection:
		connected = connection
		if connection != null:
			connection_command = "start_logging"

		elif connection == null:
			connection_command = "end_logging"

		if Config.get_value("devices.data_logging.enabled"):
			update_logging()
			Globals.main.get_node("PythonBridge").run(connection_command, data)


# Update logging on/off variables
func update_logging():
	logging["past"] = logging["current"]
	logging["current"] = Config.get_value("devices.data_logging.start")
	update_data()


# Update data to log
func update_data():
	data["folder"] = str(Config.get_value("devices.data_logging.folder"))
	data["participant"] = Config.get_value("devices.data_logging.participant_id")
	data["scene"] = scenes["current"]
	data["time"] = Time.get_unix_time_from_system()
	data["instrumented_wheels"] = Config.get_value("devices.data_logging.instrumented_wheels")
	data["motion_capture"] = Config.get_value("devices.data_logging.motion_capture")
	data["player_trajectory"] = Config.get_value("devices.data_logging.player_trajectory")
	data["position"] = player_trajectory["position"]
	data["rotation"] = player_trajectory["rotation"]


func _ready() -> void:
	update_logging()
	if SignalBus.python_bridge_connected.is_connected(_python_signal_received) == false:
		SignalBus.python_bridge_connected.connect(_python_signal_received)
		if Config.get_value("devices.data_logging.player_trajectory") == true:
			SignalBus.player_trajectory.connect(_player_signal_received)

	if SignalBus.session_scene.is_connected(_scene_signal_received) == false:
		SignalBus.session_scene.connect(_scene_signal_received)
		# connect to main.gd and see if a scene is already on
		SignalBus.current_scene.emit(true)


func _process(_delta: float) -> void:
	if SignalBus.session_scene.is_connected(_scene_signal_received) == false:
		SignalBus.session_scene.connect(_scene_signal_received)
		if (
			Config.get_value("devices.data_logging.player_trajectory") == true
			and SignalBus.player_trajectory.is_connected(_player_signal_received) == false
		):
			SignalBus.player_trajectory.connect(_player_signal_received)

	elif Globals.main.has_node("PythonBridge") and connected == true:
		update_logging()
		# If logging is on, send current data through corresponding Python command
		if logging["current"] == true:
			# Start logging if this is the first frame for which current_logging is enabled
			if logging["past"] == false:
				Globals.main.get_node("PythonBridge").run("start_logging", data)
				# If a scene was already initiated before logging, start a trial and update scene
				if scenes["current"] != "":
					Globals.main.get_node("PythonBridge").run("create_trial", data)

			# If any scene is running, send player data at each frame
			if scenes["current"] != "":
				Globals.main.get_node("PythonBridge").run("data_logging", data)

		# Otherwise, if logging is not currently on but was in the previous frame, end the process
		elif logging["past"] == true:
			Globals.main.get_node("PythonBridge").run("end_trial", data)
			player_trajectory["position"] = NAN
			player_trajectory["rotation"] = NAN

	if not Config.get_value("devices.data_logging.enabled"):
		queue_free()
