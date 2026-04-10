extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

# Bridge Godot and Python variables
@export var UDP_SEND_IP: String = "127.0.0.1" # Python IP
@export var UDP_SEND_PORT: int = 4243 # Python port
@export var UDP_RECEIVE_PORT: int = 4242 # Godot port
var _udp_receiver = PacketPeerUDP.new()
var _udp_sender = PacketPeerUDP.new()
var _udp_receiver_connected = false
var data

# Python script path
const python_path = "devices/python/python.py"


func _ready():
	
	# Launch Python app
	var python_app_path = Config.get_value("python_app.path")
	var script_path = ProjectSettings.globalize_path(python_path)
	OS.create_process(python_app_path, [script_path])
	
	# Set UDP receiver and UDP sender
	_udp_receiver.bind(UDP_RECEIVE_PORT)
	_udp_sender.connect_to_host(UDP_SEND_IP, UDP_SEND_PORT)

	# Waiting ping request from Python
	while _udp_receiver.get_available_packet_count() == 0:
		await get_tree().create_timer(1.0).timeout
	_udp_receiver_connected = true

func _process(_delta):
	
	if main:
		if not Config.get_value("devices.python.enabled"):
			queue_free()


## Listening Python response
func receive_data(): 
	
	if _udp_receiver.get_available_packet_count() > 0:  # We received something
		
		data = _udp_receiver.get_packet()
		
		var json_string = data.get_string_from_utf8()
		var json = JSON.new()
		json.parse(json_string)
		
		data = json.get_data()
		
		return data


## Sending Godot request to Python
func send_request(_request):
	
	_request = str(_request)
	_udp_sender.put_packet(_request.to_utf8_buffer())


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
	send_request({"command": "close"})
