extends Node3D

@export var anim_tree: AnimationTree
@export var max_speed : float = 2
@export var acceleration : float = 1
var current_speed : float
var target_speed : float

@onready var detection_area: Area3D = $Area3D
@onready var pathFollow: PathFollow3D = get_parent()
var nb_obstacle : int = 0

func _ready():
	anim_tree.active = true

func _process(delta):
	# There is speed lerp only for going on walk, not for stopping
	if (nb_obstacle < 1):
		target_speed = max_speed
		current_speed = move_toward(current_speed, target_speed, delta * acceleration)
	else:
		current_speed = 0

	anim_tree.set("parameters/blend_position", current_speed/target_speed)
	pathFollow.progress += current_speed * delta

func _on_area_3d_area_shape_entered(area_rid: RID, area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	if (area.is_in_group("NPC")):
		nb_obstacle += 1

func _on_area_3d_area_shape_exited(area_rid: RID, area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	if (area.is_in_group("NPC")):
		nb_obstacle -= 1

func _on_trigger_body_entered(body: Node3D) -> void:
	if (body.is_in_group("Player")):
		nb_obstacle += 1

func _on_trigger_body_exited(body: Node3D) -> void:
	if (body.is_in_group("Player")):
		nb_obstacle -= 1
