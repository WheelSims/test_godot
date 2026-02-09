extends Node3D


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
var collision_detected: bool = false
#var friction: float = 0.01325
var friction: float = 0.03
var wheel_distance: float = 0.6
var force_reset: bool = true

# Private variables
var _player  # The player instance, to access its parameters
var _udp_receiver = PacketPeerUDP.new()
var _udp_receiver_connected = false
var _udp_sender = PacketPeerUDP.new()
var _default_friction: float = 0.01325
var _current_ground_friction: float
var _obstacle_friction: float = 1
var _old_mass: float = 1  # Used to send new value on mass change

# Obstacle variables
var on_any_obstacle = false
var _nb_rr_obstacle = 0
var on_rr_obstacle = false
var _nb_lr_obstacle = 0
var on_lr_obstacle = false
var _nb_rf_obstacle = 0
var on_rf_obstacle = false
var _nb_lf_obstacle = 0
var on_lf_obstacle = false
var _nb_foot_obstacle = 0
var on_foot_obstacle = false

# Functions
func _ready() -> void:
	_player = get_parent()
	_current_ground_friction = _default_friction
	_udp_receiver.bind(UDP_RECEIVE_PORT)
	_udp_sender.connect_to_host(UDP_SEND_IP, UDP_SEND_PORT)
	get_tree().set_auto_accept_quit(false)  # to send hw_enable false on quit
	send()
	force_reset = false
	send()

func _process(delta: float) -> void:
	if _player.mass != _old_mass:
		send_data(1, hardware_enabled, _player.mass, 0)
		_old_mass = _player.mass

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		hardware_enabled = false
		send()
		get_tree().quit()

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

func send() -> void:
	send_data(2, hardware_enabled, friction, friction)


func send_data(cmd, enable, arg1, arg2) -> void:
	var bytes = PackedByteArray()
	bytes.resize(20)
	bytes.encode_u32(0, int(cmd) * (2**16) + int(enable))
	bytes.encode_double(4, arg1)
	bytes.encode_double(12, arg2)
	_udp_sender.put_packet(bytes)


func _on_obstacle_colliders_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.get_groups().is_empty() and  body is not Surface:
		match body_shape_index:
			0:
				_nb_foot_obstacle += 1
				on_foot_obstacle = true
			1:
				_nb_rf_obstacle += 1
				on_rf_obstacle = true
			2:
				_nb_lf_obstacle += 1
				on_lf_obstacle = true
			3:
				_nb_lr_obstacle += 1
				on_lr_obstacle = true
			4:
				_nb_rr_obstacle += 1
				on_rr_obstacle = true
		if on_rr_obstacle or on_lr_obstacle or on_lf_obstacle or on_rf_obstacle or on_foot_obstacle:
			on_any_obstacle	 = true
			friction = _obstacle_friction

func _on_obstacle_colliders_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.get_groups().is_empty() and body is not Surface:
		match body_shape_index:
			0:
				_nb_foot_obstacle -= 1
				if _nb_foot_obstacle == 0:
					on_foot_obstacle = false
			1:
				_nb_rf_obstacle -= 1
				if _nb_rf_obstacle == 0:
					on_rf_obstacle = false
			2:
				_nb_lf_obstacle -= 1
				if _nb_lf_obstacle == 0:
					on_lf_obstacle = false
			3:
				_nb_lr_obstacle -= 1
				if _nb_lf_obstacle == 0:
					on_lr_obstacle = false
			4:
				_nb_rr_obstacle -= 1
				if _nb_rr_obstacle == 0:
					on_rr_obstacle = false
		if !on_rr_obstacle and !on_lr_obstacle and !on_lf_obstacle and !on_rf_obstacle and !on_foot_obstacle:
			on_any_obstacle = false
			friction = _current_ground_friction

func _on_player_on_simulator_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if body is Surface and not on_any_obstacle:
		friction = body.resistance
		_current_ground_friction = friction


func _on_tree_exiting() -> void:
	hardware_enabled = 0
	friction = 1
	send()
