extends Node3D

# Bridge Godot to Python variables
var PYTHON_IP = "127.0.0.1"
var PYTHON_PORT = 4243
var UDP_RECEIVE_PORT: int = 4242
var _udp_receiver = PacketPeerUDP.new()
var _udp_receiver_connected = false
var data


func _ready() -> void:
	_udp_receiver.bind(UDP_RECEIVE_PORT)

func _process(_delta):
	_receive_data()


func _receive_data(): # Listening Python response
	
	if _udp_receiver.get_available_packet_count() > 0:  # We received something
		if not _udp_receiver_connected:
			_udp_receiver_connected = true
			print("Godot connected to Python...")
		
		data = _udp_receiver.get_packet()
		# Discard everything until the very last packet we received
		while _udp_receiver.get_available_packet_count() > 0:
			data = _udp_receiver.get_packet()
		
		var json_string = data.get_string_from_utf8()
		var json = JSON.new()
		json.parse(json_string)
		
		data = json.get_data()
		print("response received : ", data)

func _send_request(_request): # Bridge functions UDP : Godot to Python

	var message_utf8 = _request.to_utf8_buffer()
	_udp_receiver.set_dest_address(PYTHON_IP, PYTHON_PORT)
	var err = _udp_receiver.put_packet(message_utf8)
	if err == OK:
		print("request sent to python : ", _request)

func _input(event): # Test function to send request to Python
	if event.is_action_pressed("ui_accept"):
		var request = '{"command": "fonction_test"}'
		_send_request(request)
