extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

@export_enum("left", "right") var side: String

func _ready() -> void:
	pass


func _process(_delta):
	if main:
		if main.player != null:
			
			var entraxe = 0.6
			var radius = 0.6
			var player_linear_speed = main.player.get_linear_speed()
			var player_angular_speed = main.player.get_angular_speed()
			var wheel_angular_speed
			
			if side == "left":
				wheel_angular_speed = -(player_linear_speed - entraxe / 2 * player_angular_speed)/radius
			elif side == "right":
				wheel_angular_speed = (player_linear_speed + entraxe / 2 * player_angular_speed)/radius

			self.rotation += Vector3(wheel_angular_speed, 0, 0) * _delta
	pass
