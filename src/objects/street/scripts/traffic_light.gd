extends Node3D
@export var red_light_bulbs : Array[MeshInstance3D] = []
@export var green_light_bulbs : Array[MeshInstance3D] = []
@export var yellow_light_bulbs : Array[MeshInstance3D] = []

@export var _red_light_ON : Material
@export var _green_light_ON : Material
@export var _yellow_light_ON : Material

@export var obstacle : Area3D
# Virtual Object to stop cars on RED light. 
var _obstacle_RED_position : Vector3

enum Direction { NS, EW }
@export var direction : Direction
enum LightState { RED, GREEN, YELLOW }

func _ready() -> void:
	if obstacle:
		_obstacle_RED_position = obstacle.global_position

func set_light_state(new_state: LightState):
	turn_off_all_lights()
	
	match new_state:
		LightState.RED:
			_turn_on_lights(red_light_bulbs, _red_light_ON)
			obstacle.global_position = _obstacle_RED_position
		
		LightState.YELLOW:
			_turn_on_lights(yellow_light_bulbs, _yellow_light_ON)
		
		LightState.GREEN:
			_turn_on_lights(green_light_bulbs, _green_light_ON)
			obstacle.global_position = _obstacle_RED_position + 5 * Vector3.DOWN
	
	

func _turn_on_lights(light_array: Array[MeshInstance3D], material: Material):
	for mesh in light_array:
		if mesh != null:
			mesh.material_override = material

func turn_off_all_lights():
	for mesh in red_light_bulbs:
		if mesh != null:
			mesh.material_override = null
	
	for mesh in yellow_light_bulbs:
		if mesh != null:
			mesh.material_override = null
	
	for mesh in green_light_bulbs:
		if mesh != null:
			mesh.material_override = null
			
