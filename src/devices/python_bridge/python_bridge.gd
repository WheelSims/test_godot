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

var queue_requests_by_id = {}  # Queue storing received request data per id
var _udp_receiver = PacketPeerUDP.new()
var _udp_sender = PacketPeerUDP.new()
var _udp_receiver_connected = false


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

	OS.create_process(python_app_path, [python_script_path], true)

	# Set UDP receiver and UDP sender
	_udp_receiver.bind(udp_receive_port)
	_udp_sender.connect_to_host(udp_send_ip, udp_send_port)

	# Waiting ping request from Python bridge
	while _udp_receiver.get_available_packet_count() == 0:
		await get_tree().create_timer(1.0).timeout
	_udp_receiver_connected = true
	if Config.get_value("devices.data_logging.enabled") == true:
		SignalBus.python_connected.emit(_udp_receiver_connected)


func _process(_delta):
	if Globals.main:
		if not Config.get_value("devices.python_bridge.enabled"):
			queue_free()
	if _udp_receiver_connected:
		_process_received_packets()
		
	if Config.get_value("devices.data_logging.enabled") == true:
		SignalBus.python_connected.emit(_udp_receiver_connected)


## Receive and save JSON data from Python bridge in requests queues
func _process_received_packets():
	while _udp_receiver.get_available_packet_count() > 0:  # We received something
		var data = _udp_receiver.get_packet()
		var json_string = data.get_string_from_utf8()
		var json = JSON.new()
		json.parse(json_string)

		for id in queue_requests_by_id:
			queue_requests_by_id[id].append(json.get_data())


## Receive data from Python.
##
## Parameters
## ----------
## id
##     Name of the receive queue. If the receive queue does not exist yet, it is created. Each
##     received data is appended to every receive queue, which ensures that calling receive() with
##     a unique queue gives access to every received packets.
##
## Returns
## -------
## Dictionary
##     If no data is available, returns an empty dictionary.
##     If data is available, returns a dictionary with keys "command", which is the name of the
##     python command that sent this data, and "data", which is a dictionary with the actual
##     data.
func receive(id: String) -> Dictionary:
	if id not in queue_requests_by_id:
		queue_requests_by_id[id] = []
		return {}
	if queue_requests_by_id[id].size() > 0:
		var last_data = queue_requests_by_id[id].pop_at(-1)
		return last_data
	return {}


## Run a Python command.
##
## Parameters
## ----------
## command
##     One of the available commands in the python_bridge.py's COMMAND_MAPPING
## args
##     A dictionary containing any information required by the command
## run_mode
##     "once" to launch the command once, "start" to run it continuously, and "stop" to
##     stop from running it continuously.
func send(command: String, args: Dictionary, run_mode: String):
	var request = {"command": command, "args": args, "run_mode": run_mode}
	_udp_sender.put_packet(JSON.stringify(request).to_utf8_buffer())


## Debug overlay
func get_debug_text() -> String:
	var text = ""
	text += "Python "
	if not _udp_receiver_connected:
		text += "not "
	text += "connected.\n"
	return text


## Close the python app when the node exits the scene tree
func _exit_tree():
	SignalBus.python_connected.emit(null)
	send("close", {}, "once")
	# Delay to allow other overlays/devices to shut down before this device
	await get_tree().create_timer(0.1).timeout
