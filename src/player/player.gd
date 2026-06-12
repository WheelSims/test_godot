## This script manages the player, including collisions with the terrain (due to gravity) and with
## the objects. Independently of the simulator hardware, the player can always be moved using the
## keyboard arrows.
##
## The player is instanciated not in the main program, but instead in each `playable_scene`, so
## that the playable scenes really are standalone and do not require an actual simulator to be
## developed, tested and played. This means that when we load a new scene, a new player is
## instanciated, and this player is destroyed when the scene is quit. This can be cumbersome in
## different situations where we need access to the player, for example:
##
## - A device (e.g., motorized rollers, joystick) needs to set the player velocity
## - We want to record the trajectory of the player in a given level
## - The crowd should always look at the player.
##
## For this matter, we can access the current player (if any) using the global
## variable `Globals.player`, which always points to the current player
## instance, and either read its global position/orientation, or get/set
## its linear/angular velocity using its public `get_linear_speed()`,
## `get_angular_speed()`, `set_linear_speed()` and `get_linear_speed()`
## functions.
extends RigidBody3D

class_name Player

# ------------------
# Editable constants
# ------------------
@export_group("Keyboard Control")
@export var KB_LINEAR_SPEED: float = 2 # m/s
@export var KB_ANGULAR_SPEED: float = 1 # rad/s
@export var LINEAR_SPEED_DEADZONE: float = 0.04 # m/s
@export var ANGULAR_SPEED_DEADZONE: float = 0.04 # rad/s


# -----------------------
# Current velocity
# -----------------------
var _device_linear_velocity: float = 0.0
var _device_angular_velocity: float = 0.0
var _keyboard_linear_velocity: float = 0.0
var _keyboard_angular_velocity: float = 0.0

# -----------------------
# Dynamics/collisions
# -----------------------
var is_front_collision: bool = false
var is_rear_collision: bool = false
var _default_rolling_resistance_coefficient: float = 0.01325
var rolling_resistance_coefficient: float = _default_rolling_resistance_coefficient
var _n_rr_obstacle = 0
var _n_lr_obstacle = 0
var _n_rf_obstacle = 0
var _n_lf_obstacle = 0
var _n_foot_obstacle = 0

# -----------------------
# Config related
# -----------------------
var _config_update_required: bool = true # Update to match config
var _camera_rotation_x_offset: float = 0.0


# -----------------------
# Public functions
# -----------------------
## Return linear speed set by device + keyboard
func get_linear_speed():
	return _device_linear_velocity + _keyboard_linear_velocity


## Return linear speed set by device + keyboard
func get_angular_speed():
	return _device_angular_velocity + _keyboard_linear_velocity


## Set linear speed from device
func set_linear_speed(value: float):
	_device_linear_velocity = value


## Set angular speed from device
func set_angular_speed(value: float):
	_device_angular_velocity = value


# -----------------------
# Godot lifecycle
# -----------------------
func _ready():
	Globals.player = self


func _process(_delta):
	if Config.value_changed("player", "player.mass") or _config_update_required:
		mass = Config.get_value("player.mass")
	if Config.value_changed("player", "player.camera.fov") or _config_update_required:
		$Camera.fov = Config.get_value("player.camera.fov")
	if Config.value_changed("player", "player.camera.angle") or _config_update_required:
		_camera_rotation_x_offset = Config.get_value("player.camera.angle") / 180 * PI
	_config_update_required = false

	# Only keep camera rotation around y (keep level)
	$Camera.rotation.x = _camera_rotation_x_offset - rotation.x
	$Camera.rotation.z = -rotation.z
	
	if (Config.get_value("devices.data_logging.enabled")==true
		and Config.get_value("devices.data_logging.player_trajectory")==true):
			# Player position and orientation are emitted to the player_trajectory signal
			SignalBus.player_trajectory.emit(global_position, rotation)


func _physics_process(delta: float) -> void:
	var desired_linear_velocity := _device_linear_velocity
	var desired_angular_velocity := _device_angular_velocity

	# Keyboard navigation
	read_keyboard_velocities()
	desired_linear_velocity += _keyboard_linear_velocity
	desired_angular_velocity += _keyboard_angular_velocity

	if abs(desired_linear_velocity) < LINEAR_SPEED_DEADZONE:
		desired_linear_velocity = 0
	if abs(desired_angular_velocity) < ANGULAR_SPEED_DEADZONE:
		desired_angular_velocity = 0

	if (
		(desired_linear_velocity >= 0 and not is_front_collision)
		or (desired_linear_velocity <= 0 and not is_rear_collision)
	):
		translate(Vector3(0, 0, -1) * desired_linear_velocity * delta)
	rotate(Vector3.UP, desired_angular_velocity * delta)


# -----------------------
# Other functions
# -----------------------
func read_keyboard_velocities():
	var linear := 0.0
	var angular := 0.0

	if Input.is_action_pressed("ui_up"):
		linear += KB_LINEAR_SPEED
	if Input.is_action_pressed("ui_down"):
		linear -= KB_LINEAR_SPEED
	if Input.is_action_pressed("ui_left"):
		angular += KB_ANGULAR_SPEED
	if Input.is_action_pressed("ui_right"):
		angular -= KB_ANGULAR_SPEED

	_keyboard_linear_velocity = linear
	_keyboard_angular_velocity = angular


func _on_obstacle_colliders_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.get_groups().is_empty() and body is not Surface:
		match local_shape_index:
			0:
				_n_foot_obstacle += 1
				is_front_collision = true
			1:
				_n_rf_obstacle += 1
				is_front_collision = true
			2:
				_n_lf_obstacle += 1
				is_front_collision = true
			3:
				_n_lr_obstacle += 1
				is_rear_collision = true
			4:
				_n_rr_obstacle += 1
				is_rear_collision = true


func _on_obstacle_colliders_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.get_groups().is_empty() and body is not Surface:
		match local_shape_index:
			0:
				_n_foot_obstacle -= 1
			1:
				_n_rf_obstacle -= 1
			2:
				_n_lf_obstacle -= 1
			3:
				_n_lr_obstacle -= 1
			4:
				_n_rr_obstacle -= 1
		if (
			(_n_foot_obstacle == 0)
			and (_n_rf_obstacle == 0)
			and (_n_lf_obstacle == 0)
		):
			is_front_collision = false
		if (
			(_n_rr_obstacle == 0)
			and (_n_lr_obstacle == 0)
		):
			is_rear_collision = false


func _on_player_on_simulator_body_shape_entered(body_rid: RID, body: Node, body_shape_index: int, local_shape_index: int) -> void:
	if body is Surface:
		rolling_resistance_coefficient = body.resistance


func _on_tree_exiting() -> void:
	Globals.player = null
