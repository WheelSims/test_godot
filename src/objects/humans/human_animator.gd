@tool
## This script is associated to every human (e.g., Brian, Josh, Kate, etc.) and controls their
## animation. For now, it automatically triggers the correct movement between Walking and Idle
## based on its global speed.
extends Node3D

## Configuration options

## True to keep the human oriented toward the player.
@export var look_at_player: bool = false

## Velocity of the human, to set the orientation and walking/running animation speed
@export var current_velocity: Vector3 = Vector3(0, 0, 0)

## Distance from player at which the human start cheering
@export var cheer_distance: float = 0.0

#@onready var footstep_player = $AudioStreamPlayer3D
@onready var anim_player = $AnimationPlayer
@onready var old_position: Vector3 = Vector3(0, 0, 0)


func _process(delta):
	var current_speed = sqrt(current_velocity.x ** 2 + current_velocity.z ** 2)

	var player_position: Vector3 = Vector3.ZERO
	if (not Engine.is_editor_hint()) and Globals.player:
		player_position = Globals.player.global_position

	# Orient the human if needed
	var target_rotation_y: float
	var do_orient = false
	if look_at_player:
		target_rotation_y = atan2(
			player_position.x - global_position.x,
			player_position.z - global_position.z,
		)
		do_orient = true

	elif current_speed > 0.1:
		target_rotation_y = atan2(current_velocity.x, current_velocity.z)
		do_orient = true

	if do_orient:
		if target_rotation_y - global_rotation.y > PI:
			target_rotation_y -= 2 * PI
		elif target_rotation_y - global_rotation.y < -PI:
			target_rotation_y += 2 * PI

		# Magical 4 constant that works well visually
		global_rotation.y = lerp(global_rotation.y, target_rotation_y, delta * 4)

	# Set the correct animation
	if (player_position - global_position).length() < cheer_distance:
		anim_player.speed_scale = 1.0
		anim_player.play("human_animation_library/cheering")
		return

	if current_speed > 2.5:
		anim_player.speed_scale = current_speed / 3.5
		anim_player.play("human_animation_library/running")
		return

	if current_speed > 0.1:
		anim_player.speed_scale = current_speed / 1.6
		anim_player.play("human_animation_library/walking")
		return

	# Default = idle
	anim_player.speed_scale = 1.0
	anim_player.play("human_animation_library/idle")
