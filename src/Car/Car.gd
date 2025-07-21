extends Node3D

@onready var pathFollow: PathFollow3D = get_parent()
@export var triggers_on_curve: Array[Area3D]
var triggers_on_curve_offsets: Array[float]
@export var current_speed: float
var nb_obstacle: float = 0

# Store the original Z offsets of the triggers before resetting their positions.
func _on_ready() -> void:
	for i in triggers_on_curve.size():
		var offset = triggers_on_curve[i].position.z
		triggers_on_curve_offsets.append(offset)
		triggers_on_curve[i].position = Vector3(0,0,0)
		print(triggers_on_curve_offsets)

func _process(delta: float) -> void:
	if (nb_obstacle < 1):
		carprogress(delta)

func carprogress(delta: float) -> void:
	pathFollow.progress += current_speed * delta
	for i in triggers_on_curve.size():
		var offset_progress = pathFollow.progress + triggers_on_curve_offsets[i]
		var position_on_curve = pathFollow.get_parent().curve.sample_baked(offset_progress)
		var global_position = position_on_curve + pathFollow.get_parent().position
		triggers_on_curve[i].global_transform.origin = global_position


func _on_front_trigger_body_entered(body: Node3D) -> void:
	if (body.is_in_group("Player")):
		nb_obstacle += 1


func _on_front_trigger_body_exited(body: Node3D) -> void:
	if (body.is_in_group("Player")):
		nb_obstacle -= 1


func _on_front_trigger_area_entered(area: Area3D) -> void:
	if (area.is_in_group("NPC")):
		nb_obstacle += 1

func _on_front_trigger_area_exited(area: Area3D) -> void:
	if (area.is_in_group("NPC")):
		nb_obstacle -= 1
