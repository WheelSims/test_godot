## This script receives information from SignalBus and sends it outward through the python_bridge
extends Node2D

@onready var main: Node = get_tree().get_root().get_node("main")

# variable to hold signal received from main.gd are initiated with nulls
var scenes = { "current": "", "new": "" }

# variable to hold signals received from player.gd are initiated with nulls
var player_trajectory = { "position": NAN, "rotation": NAN }

# variable to hold signals pertaining to toggling on/off of data_logging
var logging = { "past": false, "current": false }

# Set up the dictionary to save data in
var data = { }

# whether or not connection to python was established
var connected = false

# called everytime a signal is received from main.gd to save it
func _scene_signal_received(scene_name):
	scenes["new"] = scene_name.get_file().split('.')[0].replace("_", "")

	# When logging in on, initiate a new file (trial) and update current scene if the scene is new
	if (scenes["current"] != scenes["new"] and main.has_node("python_bridge") and logging["current"] == true):
		# If a trial was in progress (i.e. previous scene is not blank), end it
		if (scenes["current"] != ""):
			main.get_node("python_bridge").send("end_logging", data, "once")
			player_trajectory["position"] = NAN
			player_trajectory["rotation"] = NAN

		scenes["current"] = scenes["new"]
		update_data()
		main.get_node("python_bridge").send("create_trial", data, "once")


# called everytime a signal is received from player.gd to save it
func _player_signal_received(pos, rot):
	player_trajectory["position"] = pos
	player_trajectory["rotation"] = rot

# called when a signal is received from python_bridge.gd
func _python_signal_received(connection, closing):
	if connection != null:
		connected = connection
		update_logging()
		main.get_node("python_bridge").send("start_logging", data, "once")
		
	elif closing != null:
		update_data()
		main.get_node("python_bridge").send("end_logging", data, "once")

# Update logging on/off variables
func update_logging():
	logging["past"] = logging["current"]
	logging["current"] = Config.get_value("devices.data_logging.start")
	if logging["current"] == true:
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
	
	if SignalBus.python_connected.is_connected(_python_signal_received) == false:
		SignalBus.python_connected.connect(_python_signal_received)


func _process(_delta: float) -> void:
	if (SignalBus.session_scene.is_connected(_scene_signal_received) == false):
		SignalBus.session_scene.connect(_scene_signal_received)
		
		if (Config.get_value("devices.data_logging.player_trajectory") == true
				and SignalBus.player_trajectory.is_connected(_player_signal_received) == false):
			SignalBus.player_trajectory.connect(_player_signal_received)
			
	elif (main.has_node("python_bridge") and connected == true):
		update_logging()
		# If logging is on, send current data through corresponding Python command
		if (logging["current"] == true):
			# Start logging if this is the first frame for which current_logging is enabled
			if (logging["past"] == false):
				print('logging was just started now!')
				main.get_node("python_bridge").send("start_logging", data, "once")
				# If a scene was already initiated before logging, start a trial and update scene
				if (scenes["current"] != ""):
					print('there was already a scene')
					main.get_node("python_bridge").send("create_trial", data, "once")

			# If any scene is running, send player data at each frame
			elif (scenes["current"] != ""):
				main.get_node("python_bridge").send("data_logging", data, "once")

		# Otherwise, if logging is not currently on but was in the previous frame, end the process
		elif (logging["past"] == true):
			main.get_node("python_bridge").send("end_logging", data, "once")
			player_trajectory["position"] = NAN
			player_trajectory["rotation"] = NAN

	if not Config.get_value("devices.data_logging.enabled"):
		queue_free()
