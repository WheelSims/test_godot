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
@export var KB_ANGULAR_SPEED: float = 3  # rad/s ?

@export_group("Motion platform")
## The URL for the custom motion platform control app
@export var MOTION_PLATFORM_URL = "localhost:8765"


# ----------------------
# Script scope variables
# ----------------------

# Our WebSocketClient instance.
var motion_platform_socket = WebSocketPeer.new()


# ---------------------------------
# Motion platform related functions
# ---------------------------------
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
func get_keyboard_velocities() -> Array[Vector3]:
	## Return [desired_linear_velocity, desired_angular_velocity] as controlled
	## by the keyboard.
	var desired_linear_velocity = Vector3.ZERO
	var desired_angular_velocity = Vector3.ZERO
		
	if Input.is_action_pressed("ui_up"):  # W key
		desired_linear_velocity -= transform.basis.z.normalized()
	if Input.is_action_pressed("ui_down"):  # S key
		desired_linear_velocity += transform.basis.z.normalized()
	if Input.is_action_pressed("ui_left"):  # A key
		desired_angular_velocity.y += 1
	if Input.is_action_pressed("ui_right"):  # D key
		desired_angular_velocity.y -= 1
	
	# Multiply by the designed speed
	desired_linear_velocity *= KB_LINEAR_SPEED
	desired_angular_velocity *= KB_ANGULAR_SPEED
	
	return [desired_linear_velocity, desired_angular_velocity]
	

# -----------------------
# Standard Godot funtions
# -----------------------
func _ready():
	init_motion_platform_socket()


# Called every frame
func _physics_process(delta: float) -> void:
	var desired_linear_velocity = Vector3.ZERO
	var desired_angular_velocity = Vector3.ZERO

	# Keyboard navigation
	var keyboard_desired_velocities = get_keyboard_velocities()
	desired_linear_velocity += keyboard_desired_velocities[0]
	desired_angular_velocity += keyboard_desired_velocities[1]

	# Set the velocities
	apply_force(1000 * (desired_linear_velocity - linear_velocity))
	apply_torque(1000 * (desired_angular_velocity - angular_velocity))
	
	# Send new orientation to DBox
	send_motion_platform_command(
			rotation_degrees.y,
			rotation_degrees.x,
			position.y,
		)
