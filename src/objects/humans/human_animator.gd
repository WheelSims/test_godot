## This script is associated to every human (e.g., Brian, Josh, Kate, etc.) and controls their
## animation. For now, it automatically triggers the correct movement between Walking and Idle
## based on its global speed.
extends Node3D

#@onready var footstep_player = $AudioStreamPlayer3D
@onready var anim_player = $AnimationPlayer
@onready var old_position: Vector3 = Vector3(0, 0, 0)
@onready var current_velocity: Vector3 = Vector3(0, 0, 0)


func _physics_process(delta):
	current_velocity = (global_position - old_position) / delta
	old_position = global_position


func _process(delta):
	
	# Look in direction of the next path position
	# (didn't use look_at because the pedestrian should stay upright).
	var current_speed = current_velocity.length()
	if current_speed > 0.1:
		var target_rotation_y : float = atan2(current_velocity.x, current_velocity.z)
		if target_rotation_y - rotation.y > PI:
			target_rotation_y -= 2*PI
		elif target_rotation_y - rotation.y < -PI:
			target_rotation_y += 2*PI
		rotation.y = lerp(rotation.y, target_rotation_y, delta*4)  # Magical 4

	
	if current_speed < 0.1:
		anim_player.speed_scale = 1.0
		anim_player.play("human_animation_library/idle")
	elif current_speed > 2.5:
		anim_player.speed_scale = current_speed / 3.5
		anim_player.play("human_animation_library/running")
	else:
		anim_player.speed_scale = current_speed / 1.6
		anim_player.play("human_animation_library/walking")
