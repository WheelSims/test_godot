extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

@export var UDP_SEND_IP: String = "127.0.0.1" # Python IP
@export var UDP_SEND_PORT: int = 4243 # Python port
@export var UDP_RECEIVE_PORT: int = 4242 # Godot port
var _udp_receiver = PacketPeerUDP.new()
var _udp_sender = PacketPeerUDP.new()
var _udp_receiver_connected = false


func _ready():
	# Launch Python app
	var python_app_path: String = Config.get_value("devices.python_bridge.python_path")
	var python_script_path: String = Config.get_value("devices.python_bridge.script_path")

	if (python_app_path == ""):
		print("Cannot launch Python because Python app path is unset.")
		return

	if (python_script_path == ""):
		print("Cannot launch Python because Python app script is unset.")
		return

	OS.create_process(python_app_path, [python_script_path], true)

	# Set UDP receiver and UDP sender
	_udp_receiver.bind(UDP_RECEIVE_PORT)
	_udp_sender.connect_to_host(UDP_SEND_IP, UDP_SEND_PORT)

	# Waiting ping request from Python
	while _udp_receiver.get_available_packet_count() == 0:
		await get_tree().create_timer(1.0).timeout
	_udp_receiver_connected = true


func _process(_delta):
	if main:
		if not Config.get_value("devices.python_bridge.enabled"):
			queue_free()


## Receive JSON data from Python
func receive_data():
	var data

	if _udp_receiver.get_available_packet_count() > 0: # We received something
		data = _udp_receiver.get_packet()

		var json_string = data.get_string_from_utf8()
		var json = JSON.new()
		json.parse(json_string)

		return json.get_data()


## Sending JSON data to Python
func send_request(data):
	_udp_sender.put_packet(JSON.stringify(data).to_utf8_buffer())


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
	send_request({ "command": "close" })
