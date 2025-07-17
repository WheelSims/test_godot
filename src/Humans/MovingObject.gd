extends Node3D

@export var anim_tree: AnimationTree
@export var max_speed : float = 2
@export var acceleration : float = 1
var current_speed : float
var target_speed : float

@onready var detection_area: Area3D = $Area3D
@onready var pathFollow: PathFollow3D = get_parent()
var is_blocked : int = 0

func _ready():
	anim_tree.active = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if (body.is_in_group("NPC") or body.is_in_group("Player")):
		is_blocked += 1

func _on_area_3d_body_exited(body: Node3D) -> void:
	if (body.is_in_group("NPC") or body.is_in_group("Player")):
		is_blocked -= 1
	
func _process(delta):
	# There is speed lerp only for going on walk, not for stopping
	if (is_blocked < 1):
		target_speed = max_speed
		current_speed = move_toward(current_speed, target_speed, delta * acceleration)
	else:
		print("detected")
		current_speed = 0

	anim_tree.set("parameters/blend_position", current_speed/target_speed)
	pathFollow.progress += current_speed * delta
