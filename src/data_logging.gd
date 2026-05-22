## This script receives information from SignalBus and sends it outward through
## the python_bridge
extends Node2D

@onready var main: Node = get_tree().get_root().get_node("main")

## variable to hold signal received from config.gd is initiated with null
#var p_id = NAN 

# variables to hold signal received from main.gd are initiated with nulls
var new_scene = "" 
var current_scene = ""

# variables to hold signals received from player.gd are initiated with nulls
var player_position = NAN 
var player_rotation = NAN 

## called everytime a signal is received from config.gd to save it
#func _config_signal_received(data1):
#	p_id = data1

# called everytime a signal is received from main.gd to save it
func _scene_signal_received(data1):
	new_scene = data1.get_file().split('.')[0].replace("_", "")

# called everytime a signal is received from player.gd to save it
func _player_signal_received(data1, data2):
	player_position = data1
	player_rotation = data2

func _process(_delta: float) -> void:
	if(SignalBus.player_trajectory.is_connected(_player_signal_received)==false
		or SignalBus.session_scene.is_connected(_scene_signal_received)==false):
		SignalBus.session_scene.connect(_scene_signal_received)
		print('Connection established with main.gd')
		
		if(Config.get_value("devices.data_logging.player_trajectory")==true):
			# establishing connection with player.gd through SignalBus
			SignalBus.player_trajectory.connect(_player_signal_received)
			print('Connection established with player.gd')
	
	# check that we can access the python_bridge
	if(SignalBus.player_trajectory.is_connected(_player_signal_received)==true
		and main.has_node("python_bridge")):
		# only create a new file if a new scene is initiated
		# MH: Qs for FC: double-click problem
		if (current_scene!=new_scene):
			var data_filename = {"folder": str(Config.get_value("devices.data_logging.folder")),
								"scene": new_scene,
								"participant": Config.get_value("devices.data_logging.participant_id"),
								"player_position": Config.get_value("devices.data_logging.player_trajectory"),
								"player_rotation": Config.get_value("devices.data_logging.player_trajectory"),
								"instrumented_wheels": Config.get_value("devices.data_logging.instrumented_wheels"),
								"motion_capture": Config.get_value("devices.data_logging.motion_capture")}
			
			main.get_node("python_bridge").send_request({"command": "create_file", 
														"run_mode": "once",
														 "args": data_filename})
			# update the current_scene variable
			current_scene = new_scene
	
		# once any scene is initiated, send player data at each iteration
		if (current_scene!=""):
			var timestamp = Time.get_unix_time_from_system()
			var data_to_save = {"folder": Config.get_value("devices.data_logging.folder"),
								"scene": current_scene,
								"participant": Config.get_value("devices.data_logging.participant_id"),
								"time": timestamp}
			
			# save player_trajectory only if this option is toggled on
			if(Config.get_value("devices.data_logging.player_trajectory")==true):
				data_to_save["position"] = player_position
				data_to_save["rotation"] = player_rotation
				#print('position ', player_position, ' - rotation ', player_rotation)
			
			# draft for later, when instrumented_wheels and motion_capture are set up
			# if(Config.get_value("devices.data_logging.instrumented_wheels")==true):
			#	data_to_save["wheels"] = player_wheels
			# if(Config.get_value("devices.data_logging.motion_capture")==true):
			#	data_to_save["motion"] = player_motion
			
			# communicate the information to be saved in the file
			main.get_node("python_bridge").send_request({"command": "data_logging", 
														"run_mode": "once",
														"args": data_to_save})
	
	else:
		print('Connection could not be established from data_logging.gd to python_bridge.gd')
		
	if not Config.get_value("devices.data_logging.enabled"):
		queue_free()
