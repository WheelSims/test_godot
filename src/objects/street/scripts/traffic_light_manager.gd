extends Node3D
@export var traffic_lights : Array[Node3D] = []
@export var pedestrian_traffic_lights : Array[PedestrianTrafficLight] = []

enum Direction {NS, EW}
var _currentDirection : Direction = Direction.NS

@export var green_light_duration = 30
@export var yellow_light_duration = 2
@export var walk_man_ratio = 0.3
var _walk_man_duration = 0
var yellow_on = false
var _timer : float

func _ready() -> void:
	_walk_man_duration = green_light_duration * walk_man_ratio
	_timer = 0
	for traffic_light in traffic_lights:
		if (traffic_light.direction == Direction.NS):
			traffic_light.set_light_state(traffic_light.LightState.GREEN)
		else:
			traffic_light.set_light_state(traffic_light.LightState.RED)

func _process(delta: float) -> void:
	_timer += delta

	if _timer < _walk_man_duration:
		_show_walk()
	elif _timer < green_light_duration:
		_show_hand_blink()
	elif _timer < green_light_duration + yellow_light_duration:
		if not yellow_on:
			_reset_light()
			_set_yellow()
	else:
			_timer = 0
			yellow_on = false
			_set_green_red()	

### Car traffic light functions
func _set_yellow():
	yellow_on = true
	_currentDirection = opposite(_currentDirection)

	for traffic_light in traffic_lights:
		if traffic_light.direction == opposite(_currentDirection):
			traffic_light.set_light_state(traffic_light.LightState.YELLOW)
			
func _set_green_red():
	for traffic_light in traffic_lights:
		if traffic_light.direction == opposite(_currentDirection):
			traffic_light.set_light_state(traffic_light.LightState.RED)
		else:
			traffic_light.set_light_state(traffic_light.LightState.GREEN)

func opposite(direction : Direction) -> Direction:
	return Direction.EW if direction == Direction.NS else Direction.NS
	
### Pedestrian traffic light functions
func _show_walk() -> void:
	for ptl in pedestrian_traffic_lights:
		if ptl.direction == _currentDirection:
			ptl.show_walk()

func _show_hand_blink() -> void:
	for ptl in pedestrian_traffic_lights:
		if ptl.direction == _currentDirection:
			ptl.show_hand_blink()
			ptl.update_counter(green_light_duration - _timer)

func _reset_light() -> void:
	for ptl in pedestrian_traffic_lights:
		if ptl.direction == _currentDirection:
			ptl.reset_light()
