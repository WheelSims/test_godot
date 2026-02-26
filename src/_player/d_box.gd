extends Node3D

@export var UDP_SEND_IP: String = "127.0.0.1"
@export var UDP_SEND_PORT: int = 25200

## AP distance between actuators (m)
@export var SIMULATOR_LENGTH: float = 0.914
## ML distance between actuators (m)
@export var SIMULATOR_WIDTH: float = 0.914
## Actuator max excursion (m)
@export var ACTUATOR_LENGTH: float = 0.1524
## Max height amplitude to simulate (m): set 0 (nothing) to get full range of angles
@export var MAX_HEIGHT_AMPLITUDE: float = 0.05
## Time window for normalizing height around 0 (s)
@export var HEIGHT_NORMALIZATION_WINDOW: float = 1.5
## Speed-dependent vibration level
@export var VIBRATION_LEVEL: float = 0.2

# --- Mode manuel ---
var manual_mode := false
var manual_target_heave: float = 0.0  # consigne envoyée par le menu en manuel

# Pré-calculs
var max_pitch_angle = atan(ACTUATOR_LENGTH / SIMULATOR_LENGTH)
var max_roll_angle  = atan(ACTUATOR_LENGTH / SIMULATOR_WIDTH)
var max_height = ACTUATOR_LENGTH / 2.0
var max_simulated_height = MAX_HEIGHT_AMPLITUDE / 2.0

# Privé
var _udp_sender = PacketPeerUDP.new()

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
	_udp_sender.connect_to_host(UDP_SEND_IP, UDP_SEND_PORT)
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

@onready var player: RigidBody3D = get_parent()

@onready var old_dbox_normalized_height: float = 0.0
@onready var old_real_height: float = 0.0

@onready var old_height_noise: float = 0.0
@onready var old_pitch_noise: float = 0.0
@onready var old_roll_noise: float = 0.0
@onready var old_position = global_position

func _process(delta: float) -> void:
	# --- MODE MANUEL ---
	if manual_mode:
		# on fige l'état auto pour éviter les sauts ensuite
		old_dbox_normalized_height = 0.0
		old_real_height = global_position.y

		# limite de sécurité
		var limit: float = max_simulated_height / max_height
		var heave: float = clampf(manual_target_heave, -limit, limit)

		# envoi (pitch/roll = 0 pour ce manuel simple)
		send(7, heave, 0.0, 0.0)
		return

	# --- MODE AUTO (vibrations + inclinaisons) ---
	var normalized_height_delta: float = (global_position.y - old_real_height) / max_height
	var dbox_new_normalized_height: float = old_dbox_normalized_height + normalized_height_delta

	# Limites
	var lim: float = max_simulated_height / max_height
	dbox_new_normalized_height = clampf(dbox_new_normalized_height, -lim, lim)

	# Retour progressif vers 0
	dbox_new_normalized_height = dbox_new_normalized_height * (HEIGHT_NORMALIZATION_WINDOW - delta) / HEIGHT_NORMALIZATION_WINDOW

	# Mémos
	old_dbox_normalized_height = dbox_new_normalized_height
	old_real_height = global_position.y

	# Bruit (feeling)
	var height_noise_delta: float = randf_range(-VIBRATION_LEVEL, VIBRATION_LEVEL)
	var height_noise: float = old_height_noise + delta * height_noise_delta - (50.0 * delta) * old_height_noise
	old_height_noise = height_noise

	var pitch_noise_delta: float = randf_range(-VIBRATION_LEVEL, VIBRATION_LEVEL)
	var pitch_noise: float = old_pitch_noise + delta * pitch_noise_delta - (50.0 * delta) * old_pitch_noise
	old_pitch_noise = pitch_noise

	var roll_noise_delta: float = randf_range(-VIBRATION_LEVEL, VIBRATION_LEVEL)
	var roll_noise: float = old_roll_noise + delta * roll_noise_delta - (50.0 * delta) * old_roll_noise
	old_roll_noise = roll_noise

	var velocity = (global_position - old_position) / delta
	var speed = sqrt(velocity.dot(velocity))
	old_position = global_position

	send(
		7,
		dbox_new_normalized_height + (height_noise * speed),
		-player.rotation.x / max_pitch_angle + (pitch_noise * speed),
		player.rotation.z / max_roll_angle + (roll_noise * speed)
	)
