extends Node3D

@export var anim_tree: AnimationTree
@export var max_speed : float = 2
@export var acceleration : float = 1
var current_speed : float
var target_speed : float

@export var detection_area: Area3D
@onready var pathFollow: PathFollow3D = get_parent().get_parent()
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

func _on_trigger_area_entered(area: Area3D) -> void:
	if (area.is_in_group("NPC")):
		nb_obstacle += 1


func _on_trigger_area_exited(area: Area3D) -> void:
	if (area.is_in_group("NPC")):
		nb_obstacle -= 1
