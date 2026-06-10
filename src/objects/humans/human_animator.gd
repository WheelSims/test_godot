## This script is associated to every human (e.g., Brian, Josh, Kate, etc.) and controls their
## animation. For now, it automatically triggers the correct movement between Walking and Idle
## based on its global speed.
extends Node3D

#@onready var footstep_player = $AudioStreamPlayer3D
@onready var anim_player = $AnimationPlayer
@onready var old_position: Vector3 = Vector3(0, 0, 0)
@onready var current_speed: float = 0.0
@export var max_speed: float = 1.6 # Speed at which the walking motion is recorded in the animation


func _physics_process(delta):
	current_speed = (global_position - old_position).length() / delta
	old_position = global_position


func _process(_delta):
	anim_player.speed_scale = current_speed / max_speed
	if current_speed < 0.1:
		anim_player.play("HumanAnimations/idle")
	else:
		anim_player.play("HumanAnimations/walking")
