# Race.gd
class_name Race
extends Resource  # ou Object, ou même Node si tu veux

var timer: float = 0.0
var current_distance: float = 0.0
var player: RigidBody3D
var player_pos: Vector3
var last_player_pos: Vector3

func _init(_player: RigidBody3D):
	player = _player
	player_pos = player.global_position
	
func update(delta: float):
	_calculate_distance()
	timer += delta
	
func _calculate_distance() -> void:
	last_player_pos = player_pos
	player_pos = player.global_position
	current_distance += (player_pos - last_player_pos).length()
