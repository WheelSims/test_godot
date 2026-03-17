extends RigidBody3D
class_name Player

@onready var main: Node = get_tree().get_root().get_node("main")

# ------------------
# Editable constants
# ------------------
@export_group("Keyboard Control")
@export var KB_LINEAR_SPEED: float = 2  # m/s
@export var KB_ANGULAR_SPEED: float = 1  # rad/s

# -----------------------
# Custom nodes
# -----------------------
@onready var motors = get_node_or_null("motors")
@onready var player_text_node: Label = get_node_or_null(
	"ui/player_text"
)

# -----------------------
# Current velocity
# -----------------------
var _device_linear_velocity: float = 0.0
var _device_angular_velocity: float = 0.0
var _keyboard_linear_velocity: float = 0.0
var _keyboard_angular_velocity: float = 0.0

# -----------------------
# Check for value updates
# -----------------------
@onready var _old_mass: float = mass

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

#Access to race_manager
var race_manager: RaceManager = null


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
	pass

func _process(delta):
	if main:
		if main.config.get_value("player.mass") != _old_mass:
			mass = main.config.get_value("player.mass")
			_old_mass = mass
			print(mass)
		$camera.fov = main.config.get_value("player.camera.fov")
		$camera.rotation.x = main.config.get_value("player.camera.angle") / 180 * PI

func _physics_process(delta: float) -> void:
	var desired_linear_velocity := _device_linear_velocity
	var desired_angular_velocity := _device_angular_velocity
	
	# Keyboard navigation
	read_keyboard_velocities()
	desired_linear_velocity += _keyboard_linear_velocity
	desired_angular_velocity += _keyboard_angular_velocity
	
	#Other inputs (esc)
	inputs()
	
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
	
	
func inputs()->void:
	if Input.is_action_just_pressed("ui_cancel") and race_manager:
		race_manager.pause_command()

func _on_obstacle_colliders_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	if body.get_groups().is_empty() and  body is not Surface:
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
