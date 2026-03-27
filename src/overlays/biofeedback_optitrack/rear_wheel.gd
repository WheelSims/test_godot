extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")
@onready var config: Node = get_tree().get_root().get_node("main/config")

# Selected side of the wheelchair (left or right)
@export_enum("left", "right") var side: String

# Fixed wheelchair parameters
var mediolateral_distance_wheel
var radius

# Player speed parameters
var player_linear_speed
var player_angular_speed

var wheel_angular_speed


func _ready() -> void:
	pass


func _process(_delta):
	if main:
		if main.player != null:
			
			# Get fixed wheelchair parameters
			mediolateral_distance_wheel = abs(config.get_value("coordinates.left_wheel_center")[2] - config.get_value("coordinates.right_wheel_center")[2])
			radius = config.get_value("player.wheel_diameter")
			
			# Get current player linear and angular speeds
			player_linear_speed = main.player.get_linear_speed()
			player_angular_speed = main.player.get_angular_speed()
			
			# Compute angular speed of the wheel
			if side == "left":
				wheel_angular_speed = -(player_linear_speed - mediolateral_distance_wheel / 2 * player_angular_speed)/radius
			elif side == "right":
				wheel_angular_speed = (player_linear_speed + mediolateral_distance_wheel / 2 * player_angular_speed)/radius

			# Apply computed rotation to the wheel for this frame
			self.rotation += Vector3(wheel_angular_speed, 0, 0) * _delta
	pass
