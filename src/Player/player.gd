## Control script for the player object
##
## This script controls the behaviour of the player and connects it to
## optional external equipment using sockets (e.g. DBox Motion Platform).
extends RigidBody3D

# ------------------
# Editable constants
# ------------------

@export_group("Keyboard Control")
## The linear speed in m/s when we control the player using the keyboard
@export var KB_LINEAR_SPEED: float = 3  # m/s
## The angular speed in rad/s when we control the player using the keyboard
@export var KB_ANGULAR_SPEED: float = 1  # rad/s


@export_group("Motion platform")
## The URL for the custom motion platform control app
@export var MOTION_PLATFORM_URL = "localhost:8765"


# ---------------------------------
# Motion platform related functions
# ---------------------------------
var motion_platform_socket = WebSocketPeer.new()

func init_motion_platform_socket() -> void:
	## Initiate connection to the given URL.
	var err = motion_platform_socket.connect_to_url(MOTION_PLATFORM_URL)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		# Wait for the motion_platform_socket to connect.
		await get_tree().create_timer(2).timeout

func send_motion_platform_command(
	angle1: float,
	angle2: float,
	height: float,
) -> void:
	## Send a command to the motion platform.
	motion_platform_socket.poll()
	var state = motion_platform_socket.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		#TODO This is a dummy value for now.
		motion_platform_socket.send_text(str(angle1))


# --------------------------------
# Keyboard-input related functions
# --------------------------------
func get_keyboard_velocities() -> Array[float]:
	## Return [desired_linear_velocity, desired_angular_velocity] as controlled
	## by the keyboard.
	var desired_linear_velocity: float = 0
	var desired_angular_velocity: float = 0
		
	if Input.is_action_pressed("ui_up"):  # W key
		desired_linear_velocity += KB_LINEAR_SPEED
	if Input.is_action_pressed("ui_down"):  # S key
		desired_linear_velocity -= KB_LINEAR_SPEED
	if Input.is_action_pressed("ui_left"):  # A key
		desired_angular_velocity += KB_ANGULAR_SPEED
	if Input.is_action_pressed("ui_right"):  # D key
		desired_angular_velocity -= KB_ANGULAR_SPEED
	
	return [desired_linear_velocity, desired_angular_velocity]
	


# ----------
# PlayerText
# ----------
@onready var player_text_node = get_node("UI/PlayerText")
func set_player_text(text: String):
	player_text_node.text = text

# -----------------------
# Standard Godot funtions
# -----------------------
@onready var motors = get_node("Motors")
func _ready():
	init_motion_platform_socket()

# Called every frame
func _physics_process(delta: float) -> void:
	var desired_linear_velocity: float = 0
	var desired_angular_velocity: float = 0

	# Keyboard navigation
	var keyboard_desired_velocities = get_keyboard_velocities()
	desired_linear_velocity += keyboard_desired_velocities[0]
	desired_angular_velocity += keyboard_desired_velocities[1]
	
	# Rollers navigation
	motors.receive()
	motors.send()
	desired_linear_velocity += motors.linear_velocity
	desired_angular_velocity += motors.angular_velocity

	# Set the velocities
	translate(Vector3(0,0,-1) * desired_linear_velocity * delta)
	rotate(Vector3(0,1,0), desired_angular_velocity * delta)
	
	# Send new orientation to DBox
	send_motion_platform_command(
			rotation_degrees.y,
			rotation_degrees.x,
			position.y,
		)

	# Set text
	var text: String
	if motors.emergency_stop:
		text = "\nMotors OFF"
	else:
		text = str(abs(desired_linear_velocity)).pad_decimals(1) + " m/s"
	set_player_text(text)
