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
@onready var player_text_node = get_node_or_null("UI/PlayerText")
func set_player_text(text: String):
	player_text_node.text = text

# -----------------------
# Standard Godot funtions
# -----------------------
@onready var motors = get_node_or_null("Motors")
func _ready():
	pass

# Called every frame
func _physics_process(delta: float) -> void:
	var desired_linear_velocity: float = 0
	var desired_angular_velocity: float = 0

	# Keyboard navigation
	var keyboard_desired_velocities = get_keyboard_velocities()
	desired_linear_velocity += keyboard_desired_velocities[0]
	desired_angular_velocity += keyboard_desired_velocities[1]
	
	# Rollers navigation
	if motors != null:
		motors.receive()
		motors.send()
		desired_linear_velocity += motors.linear_velocity
		desired_angular_velocity += motors.angular_velocity

	# Set the velocities
	translate(Vector3(0,0,-1) * desired_linear_velocity * delta)
	rotate(Vector3(0,1,0), desired_angular_velocity * delta)
	
	# Set text
	if (motors != null) and (player_text_node != null):
		var text: String
		if motors.emergency_stop:
			text = "\nMotors OFF"
		else:
			text = str(abs(desired_linear_velocity)).pad_decimals(1) + " m/s"
		set_player_text(text)
