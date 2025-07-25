extends Node3D


@export var UDP_SEND_IP: String = "192.168.0.200"
@export var UDP_SEND_PORT: int = 25000
@export var UDP_RECEIVE_PORT: int = 25100

# Public variables (read)
var current_increment_index: int = 0
var angular_velocity: float = 0
var linear_velocity: float = 0
var emergency_stop: bool = false

# Public variables (sent)
var hardware_enabled: float = 1
var collision_detected: bool = false
var friction: float = 0.01325
var mass: float = 90
var wheel_distance: float = 0.6
var force_reset: bool = true

# Private variables
var _udp_receiver = PacketPeerUDP.new()
var _udp_receiver_connected = false
var _udp_sender = PacketPeerUDP.new()

# Functions
func _ready() -> void:
	_udp_receiver.bind(UDP_RECEIVE_PORT)
	_udp_sender.connect_to_host(UDP_SEND_IP, UDP_SEND_PORT)
	get_tree().set_auto_accept_quit(false)  # to send hw_enable false on quit
	send()
	force_reset = false
	send()
		
func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		hardware_enabled = false
		send()
		get_tree().quit()

func receive() -> void:
	if _udp_receiver.get_available_packet_count() > 0:  # We received something
		if not _udp_receiver_connected:
			_udp_receiver_connected = true
			print("Rollers connected.")			
		var array_bytes = _udp_receiver.get_packet()
		
		# Discard everything until the very last packet we received
		while _udp_receiver.get_available_packet_count() > 0:
			array_bytes = _udp_receiver.get_packet()
		
		current_increment_index = int(array_bytes.decode_double(0))
		angular_velocity = float(array_bytes.decode_double(8))
		linear_velocity = float(array_bytes.decode_double(16))
		emergency_stop = bool(array_bytes.decode_double(24))

func send() -> void:
	var bytes = PackedByteArray()
	bytes.resize(40)
	bytes.encode_double(0, hardware_enabled)
	bytes.encode_double(8, friction)
	bytes.encode_u32(16, collision_detected)
	bytes.encode_double(20, mass)
	bytes.encode_double(28, wheel_distance)
	bytes.encode_u32(36, force_reset)
	
	_udp_sender.put_packet(bytes)
	
