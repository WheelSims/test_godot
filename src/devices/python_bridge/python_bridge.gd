## This script launches a Python script in a new Python instance. It then communicates with this
## script using two unidirectional UDP connections. The paths of the Python interpreter and Python
## script must be set in Config beforehand; this can be done easily using the GUI.
##
## The main role of this script is to outsource calculations such as propulsion analysis
## to Python, so that we benefit from advanced data processing tools and we don't slow down
## Godot's simulation.
##
## Normally, the Python script is versioned on this repository:
## https://github.com/LabMOSA/wheelsims_analysis
extends Node3D

@export var udp_send_ip: String = "127.0.0.1"  # Python IP
@export var udp_send_port: int = 4243  # Python port
@export var udp_receive_port: int = 4242  # Godot port

var _udp_receiver = PacketPeerUDP.new()
var _udp_sender = PacketPeerUDP.new()
var _signal_counter: int = 0


func _ready():
	# Launch Python app
	var python_app_path: String = Config.get_value("devices.python_bridge.python_path")
	var python_script_path: String = Config.get_value("devices.python_bridge.script_path")

	if python_app_path == "":
		print("Cannot launch Python because Python app path is unset.")
		return

	if python_script_path == "":
		print("Cannot launch Python because Python app script is unset.")
		return

	if OS.get_name() == "macOS":
		print("Launching a terminal window for Python Bridge...")
		OS.create_process(
			"/usr/bin/osascript",
			[
				"-e",
				(
					'tell app "Terminal" to do script "'
					+ python_app_path
					+ " "
					+ python_script_path
					+ '"'
				)
			]
		)
	else:
		OS.create_process(python_app_path, [python_script_path], true)

	# Set UDP receiver and UDP sender
	_udp_receiver.bind(udp_receive_port)
	_udp_sender.connect_to_host(udp_send_ip, udp_send_port)


func _process(_delta):
	if Globals.main:
		if not Config.get_value("devices.python_bridge.enabled"):
			queue_free()

	while _udp_receiver.get_available_packet_count() > 0:  # We received something
		var data = _udp_receiver.get_packet()
		var json_string = data.get_string_from_utf8()
		var json = JSON.new()
		json.parse(json_string)
		var data_dict: Dictionary = json.get_data()

		if data_dict["id"] == "ready":
			# This is the only "return value" not associated to a call from
			# Godot. Therefore there is no signal to emit or value to return.
			SignalBus.python_bridge_connected.emit(true)
			_signal_counter += 1
			return

		emit_signal(data_dict["id"], data_dict["value"])
		remove_user_signal(data_dict["id"])


## Run a Python command
##
## To use:
##     result = await python_bridge.run(python_command, kwargs)
##
## Parameters
## ----------
## command
##     Python command, as defined in the COMMAND_DICT dictionary of main.py
## kwargs
##     Optional. Arguments of the command, in the form {"argname": value, ...}
##
## Returns
## -------
## signal
##     A signal to await. The result of the Python function is returned with the
##     signal.
func run(command: String, kwargs: Dictionary = {}) -> Signal:
	var id: String = command + "_" + str(Time.get_ticks_usec()) + "_" + str(_signal_counter)
	_signal_counter += 1
	if _signal_counter >= 1000000:
		_signal_counter = 1

	var request = {"command": command, "kwargs": kwargs, "id": id}
	_udp_sender.put_packet(JSON.stringify(request).to_utf8_buffer())
	add_user_signal(id)
	return Signal(self, id)  # Reference to the created signal


## Debug overlay
func get_debug_text() -> String:
	var text = "Received " + str(_signal_counter) + " UDP packets."
	return text


## Close the python app when the node exits the scene tree
func _exit_tree():
	SignalBus.python_bridge_connected.emit()
	await run("close")
	# Delay to allow other overlays/devices to shut down before this device
	await get_tree().create_timer(0.1).timeout
