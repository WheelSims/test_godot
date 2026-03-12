extends Node3D
@onready var main: Node = get_tree().get_root().get_node("main")

@export var UDP_SEND_IP: String = "192.168.0.200"
@export var UDP_SEND_PORT: int = 25000
@export var UDP_RECEIVE_PORT: int = 25100

# Public variables (read)
var index: int = 0
var angular_velocity: float = 0
var linear_velocity: float = 0
var stopped: bool = false

# Public variables (sent)
var hardware_enabled: float = 1
var wheel_distance: float = 0.6
var force_reset: bool = true

# Private variables
var _udp_receiver = PacketPeerUDP.new()
var _udp_receiver_connected = false
var _udp_sender = PacketPeerUDP.new()
var _obstacle_friction_coefficient: float = 10

# Used to monitor value changes
var _old_mass: float = 1 
var _old_rolling_resistance_coefficient: float = 1
var _old_is_front_collision: bool = false
var _old_is_rear_collision: bool = false


# Functions
func _ready() -> void:
	_udp_receiver.bind(UDP_RECEIVE_PORT)
	_udp_sender.connect_to_host(UDP_SEND_IP, UDP_SEND_PORT)
	get_tree().set_auto_accept_quit(false)  # to send hw_enable false on quit

func _process(delta: float) -> void:
	if main.player:
		if main.player.mass != _old_mass:
			send_data(1, hardware_enabled, main.player.mass, 0)
			_old_mass = main.player.mass
		if main.player.rolling_resistance_coefficient != _old_rolling_resistance_coefficient:
			_update_friction()
			_old_rolling_resistance_coefficient = main.player.rolling_resistance_coefficient
		if main.player.is_front_collision != _old_is_front_collision:
			_update_friction()
			_old_is_front_collision = main.player.is_front_collision
		if main.player.is_rear_collision != _old_is_rear_collision:
			_update_friction()
			_old_is_rear_collision = main.player.is_rear_collision
	
	if not main.config.get_value("devices.motorized_rollers.enabled"):
		queue_free()


func get_debug_text() -> String:
	var text = ""
	text += "Motors "
	if not _udp_receiver_connected:
		text += "not "
	text += "connected.\n"
	return text

func _update_friction():
	var front_friction_coefficient: float
	var rear_friction_coefficient: float
	
	if main.player.is_front_collision:
		front_friction_coefficient = _obstacle_friction_coefficient
	else:
		front_friction_coefficient = main.player.rolling_resistance_coefficient
		
	if main.player.is_rear_collision:
		rear_friction_coefficient = _obstacle_friction_coefficient
	else:
		rear_friction_coefficient = main.player.rolling_resistance_coefficient
		
	print(
		"Rollers: Front friction update: Front = ",
		front_friction_coefficient,
		" Rear = ",
		rear_friction_coefficient,
	)
	send_data(2, hardware_enabled, front_friction_coefficient, rear_friction_coefficient)

func receive() -> void:
	if _udp_receiver.get_available_packet_count() > 0:  # We received something
		if not _udp_receiver_connected:
			_udp_receiver_connected = true
			print("Motors connected.")
		var array_bytes = _udp_receiver.get_packet()
		
		# Discard everything until the very last packet we received
		while _udp_receiver.get_available_packet_count() > 0:
			array_bytes = _udp_receiver.get_packet()
		
		var header = int(array_bytes.decode_double(0))
		index = (header / 2**28)
		var cmd = (header / 2**16) % 2**12
		stopped = header % 2**1

		linear_velocity = float(array_bytes.decode_double(4))
		angular_velocity = float(array_bytes.decode_double(12))

func send_data(cmd, enable, arg1, arg2) -> void:
	var bytes = PackedByteArray()
	bytes.resize(20)
	bytes.encode_u32(0, int(cmd) * (2**16) + int(enable))
	bytes.encode_double(4, arg1)
	bytes.encode_double(12, arg2)
	_udp_sender.put_packet(bytes)


func _on_tree_exiting() -> void:
	hardware_enabled = 0
	send_data(1, hardware_enabled, 70, 0)
