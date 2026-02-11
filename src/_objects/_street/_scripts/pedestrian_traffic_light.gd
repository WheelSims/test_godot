extends Node3D
class_name PedestrianTrafficLight

enum Direction { NS, EW }
@export var direction : Direction

@export var _hand_sprite : Sprite3D
@export var _character_sprite : Sprite3D
@export var _blink_timer : Timer
@export var counter_mesh : MeshInstance3D
@export var obstacle : Area3D
var _red_obstacle_pos

var _hand_blink : bool = false

func _ready() -> void:
	if obstacle:
		_red_obstacle_pos = obstacle.global_position
	_blink_timer.timeout.connect(_on_blink)

func show_walk() -> void:
	if _blink_timer.is_stopped():
		_blink_timer.start()
	_character_sprite.visible = true
	_hand_sprite.visible = false
	counter_mesh.visible = false
	_hand_blink = false
	obstacle.global_position = _red_obstacle_pos + 5*Vector3.DOWN

func show_hand_blink() -> void:
	_character_sprite.visible = false
	counter_mesh.visible = true
	_hand_blink = true

func reset_light() -> void:
	obstacle.global_position = _red_obstacle_pos
	_hand_blink = false
	_hand_sprite.visible = true
	update_counter(0)
	_blink_timer.stop()

func update_counter(value: float) -> void:
	var _int_value = int(ceil(value))
	counter_mesh.mesh.text = str(_int_value)


func _on_blink() -> void:
	if _hand_blink:
		_hand_sprite.visible = not _hand_sprite.visible
