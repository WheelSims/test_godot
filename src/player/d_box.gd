extends Node3D

# ------------------------------------
# Simulator geometry
# ------------------------------------
## AP distance between actuators (m)
var simulator_length: float = 0.914
## ML distance between actuators (m)
var simulator_width: float = 0.914
## Actuator max excursion (m)
var actuator_length: float = 0.1524
## Max height amplitude to simulate (m): set 0 (nothing) to get full range of angles
var max_height_amplitude: float = 0.05
## Time window for normalizing height around neutral position (s)
var height_normalization_window: float = 1.5
## Speed-dependent vibration level
var vibration_level: float = 0.2
## Time window for switching between PLAY and other modes (s)
var player_mode_switch_duration: float = 2


# Precalculation relative to the simulator geometry
var max_pitch_angle = atan(actuator_length / simulator_length)
var max_roll_angle  = atan(actuator_length / simulator_width)
var max_height = actuator_length / 2.0
var max_simulated_height = max_height_amplitude / 2.0

# ------------------------------------
# D-Box driver helper
# ------------------------------------
var udp_send_ip: String = "127.0.0.1"
var udp_send_port: int = 25200
var _udp_sender = PacketPeerUDP.new()

# ------------------------------------
# Player
# ------------------------------------
@onready var player: RigidBody3D = get_parent()

## Current height (total) of the platform
@onready var current_dbox_normalized_height: float = 0.0

## Current status between ONBOARD/PAUSE/OFFBOARD (0.0) and PLAY (1.0)
@onready var current_pause_play_status: float = 0.0

@onready var old_height_noise: float = 0.0
@onready var old_pitch_noise: float = 0.0
@onready var old_roll_noise: float = 0.0
@onready var old_position = global_position

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		send(6, 0, 0, 0)  # DBox Stop
		get_tree().quit()

func send(command: int, arg0: float, arg1: float, arg2: float) -> void:
	var bytes = PackedByteArray()
	bytes.resize(28)
	bytes.encode_s32(0, command)
	bytes.encode_double(4, arg0)
	bytes.encode_double(12, arg1)
	bytes.encode_double(20, arg2)
	_udp_sender.put_packet(bytes)

func send_print_string(text: String) -> void:
	for character in text:
		send(10, character.unicode_at(0), 0, 0)

func _ready() -> void:
	_udp_sender.connect_to_host(udp_send_ip, udp_send_port)
	get_tree().set_auto_accept_quit(false)  # pour pouvoir envoyer Stop

	# DBox init
	send_print_string("Receiving packets from Godot.\n")
	send(1, 0, 0, 0)  # Init
	send(2, 0, 0, 0)  # Open
	send(3, 0, 0, 0)  # ResetState
	send(4, 0, 0, 0)  # Config
	send(7, 0, 0, 0)  # Center
	send(5, 0, 0, 0)  # Start
	send_print_string("Init done, ready to move.\n")



func _process(delta: float) -> void:
	var normalized_height_delta: float = (global_position.y - old_position.y) / max_height

	# Adjust height_delta so that height stays inside limits so that angles are still possibles
	var new_dbox_normalized_height: float = current_dbox_normalized_height + normalized_height_delta
	var lim: float = max_simulated_height / max_height
	new_dbox_normalized_height = clampf(new_dbox_normalized_height, -lim, lim)

	# Slowly return to a neutral position
	new_dbox_normalized_height = (
		new_dbox_normalized_height
		* (height_normalization_window - delta)
		/ height_normalization_window
	)

	current_dbox_normalized_height = new_dbox_normalized_height

	# Noise (feeling)
	var height_noise_delta: float = randf_range(-vibration_level, vibration_level)
	var height_noise: float = old_height_noise + delta * height_noise_delta - (50.0 * delta) * old_height_noise
	old_height_noise = height_noise

	var pitch_noise_delta: float = randf_range(-vibration_level, vibration_level)
	var pitch_noise: float = old_pitch_noise + delta * pitch_noise_delta - (50.0 * delta) * old_pitch_noise
	old_pitch_noise = pitch_noise

	var roll_noise_delta: float = randf_range(-vibration_level, vibration_level)
	var roll_noise: float = old_roll_noise + delta * roll_noise_delta - (50.0 * delta) * old_roll_noise
	old_roll_noise = roll_noise

	var velocity = (global_position - old_position) / delta
	var speed = sqrt(velocity.dot(velocity))
	
	old_position = global_position
	
	# Adjust current_pause_play_status
	if player.current_mode == player.CurrentMode.PLAY:
		if current_pause_play_status < 1.0:
			current_pause_play_status += delta / player_mode_switch_duration
	else:
		if current_pause_play_status > 0.0:
			current_pause_play_status -= delta / player_mode_switch_duration

	if current_pause_play_status > 1.0:
		current_pause_play_status = 1.0
	elif current_pause_play_status < 0.0:
		current_pause_play_status = 0.0


	send(
		7,
		new_dbox_normalized_height + (height_noise * speed) - 1.0 + current_pause_play_status,
		(-player.rotation.x / max_pitch_angle + (pitch_noise * speed)) * current_pause_play_status,
		(player.rotation.z / max_roll_angle + (roll_noise * speed)) * current_pause_play_status
	)
