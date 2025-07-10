extends RigidBody3D

var LINEAR_SPEED: float = 3  # m/s
var ANGULAR_SPEED: float = 3  # rad/s ?

# Called every frame
func _physics_process(delta: float) -> void:
	var desired_linear_velocity = Vector3.ZERO
	var desired_angular_velocity = Vector3.ZERO

	# Check for input and set the direction vector
	if Input.is_action_pressed("ui_up"):  # W key
		desired_linear_velocity -= transform.basis.z.normalized()
	if Input.is_action_pressed("ui_down"):  # S key
		desired_linear_velocity += transform.basis.z.normalized()
	if Input.is_action_pressed("ui_left"):  # A key
		desired_angular_velocity.y += 1
	if Input.is_action_pressed("ui_right"):  # D key
		desired_angular_velocity.y -= 1
	
	# Multiply by the designed speed
	desired_linear_velocity *= LINEAR_SPEED
	desired_angular_velocity *= ANGULAR_SPEED

	apply_force(1000 * (desired_linear_velocity - linear_velocity))
	apply_torque(1000 * (desired_angular_velocity - angular_velocity))
