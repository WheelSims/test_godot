extends RigidBody3D

# ------------------
# Editable constants
# ------------------
@export_group("Keyboard Control")
@export var KB_LINEAR_SPEED: float = 2  # m/s
@export var KB_ANGULAR_SPEED: float = 1  # rad/s


# -----------------------
# Current mode
# -----------------------
enum CurrentMode {
	ONBOARDING = 0,
	PLAYING = 1,
	PAUSE = 2,
	OFFBOARDING = 3
}
@onready var current_mode = CurrentMode.PLAYING

# -----------------------
# Custom nodes
# -----------------------
@onready var motors = get_node_or_null("motors")
@onready var player_text_node: Label = get_node_or_null(
	"ui/player_text"
)

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
# Godot lifecycle
# -----------------------
func _ready():
	pass

func _physics_process(delta: float) -> void:
	var desired_linear_velocity := 0.0
	var desired_angular_velocity := 0.0
	
	# Keyboard navigation
	var keyboard_desired_velocities = get_keyboard_velocities()
	desired_linear_velocity += keyboard_desired_velocities[0]
	desired_angular_velocity += keyboard_desired_velocities[1]
	
	#Other inputs (esc)
	inputs()
	
	# Rollers navigation
	if motors != null:
		motors.receive()
		
		desired_linear_velocity += motors.linear_velocity
		desired_angular_velocity += motors.angular_velocity

	# Appliquer les mouvements
	if (
		(desired_linear_velocity >= 0 and not is_front_collision)
		or (desired_linear_velocity <= 0 and not is_rear_collision)
	):
		translate(Vector3(0, 0, -1) * desired_linear_velocity * delta)
	rotate(Vector3.UP, desired_angular_velocity * delta)

	# Affichage vitesse
	if motors and player_text_node:
		var text: String
		if motors.stopped:
			text = "\nMotors OFF"
		else:
			text = str(abs(desired_linear_velocity)).pad_decimals(1) + " m/s"
		set_player_text(text)

# -----------------------
# Fonctions auxiliaires
# -----------------------
func get_keyboard_velocities() -> Array[float]:
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
		
	return [linear, angular]
	
func inputs()->void:
	if Input.is_action_just_pressed("ui_cancel") and race_manager:
		race_manager.pause_command()

func set_player_text(text: String):
	if player_text_node:
		player_text_node.text = text
		

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
