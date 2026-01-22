extends Node3D

var player: Node3D
var current_race_objects: Array[Node3D] = []
@export var restart_pos: Node3D
@export var end_offset_to_restart: float
@export var race_data: Array[RaceData]
var current_race_data_indice := 0
var current_race_data
var default_border_sample: PackedScene
var default_obstacle_sample: PackedScene
@export var border_sample: PackedScene
@export var obstacle_sample: PackedScene
@export var finish_line: PackedScene
var finish_line_instance : Node3D
@export var start_line: PackedScene
var start_line_instance : Node3D
@export var ground_tile: PackedScene
var tile_length : float = 2  #the tile is a square
var current_tiles: Array[Node3D] = []


var race_length: int = 100
var race_width: float = 10
var object_size_range: Vector2 = Vector2(0.5,3)
var depth_dist_btw_object_range: Vector2 = Vector2(5,20)
var horiz_dist_btw_object_range: Vector2 = Vector2(3,5)
var min_passage_size = 2

var _rng = RandomNumberGenerator.new()
var _depth_dist: float
var _horiz_dist: float
var _object_size: float

var _race_start_x : float = 0
var _current_x_pos : float = 0
var _end_race_x_pos : float = 0

func _ready() -> void:
	_rng.randomize()
	default_border_sample = border_sample
	default_obstacle_sample = obstacle_sample
	if race_data.size()>0:
		current_race_data = race_data[0]
		_change_current_parameters()
	_obstacle_generation()
	_arches_generation()
	_border_generation()
	_ground_generation()
	
	for i in range(race_data.size()):
		_next_level()


func _next_level() -> void:
	current_race_data_indice += 1
	if race_data.size()<=current_race_data_indice:
		print("fin")
		return
	_current_x_pos += end_offset_to_restart
	_race_start_x = _current_x_pos

	_change_current_parameters()
	_obstacle_generation()
	_arches_generation()
	_border_generation()
	_ground_generation()

func _ground_generation():
	var x_count = ceil((race_length + end_offset_to_restart) / tile_length)
	var z_count = ceil(race_width / tile_length)

	for i in range(x_count):
		for j in range(z_count):
			var tile: Node3D = ground_tile.instantiate()
			tile.position = Vector3(
				_race_start_x + i * tile_length + tile_length / 2.0,
				0,
				j * tile_length - race_width / 2 + tile_length / 2.0
			)
			add_child(tile)
			current_tiles.append(tile)
	
func _arches_generation()->void:
	if (current_race_data_indice>0):
		var start_line_instance : Node3D = start_line.instantiate()
		add_child(start_line_instance)
		start_line_instance.position.x = _race_start_x
		start_line_instance.rotate(Vector3.UP, -PI/2)
		var left_crowd : Crowd = start_line_instance.get_child(1)
		var right_crowd : Crowd = start_line_instance.get_child(2)
		left_crowd.on_race = true
		right_crowd.on_race = true
	finish_line_instance = finish_line.instantiate()
	add_child(finish_line_instance)
	finish_line_instance.position.x = _current_x_pos
	finish_line_instance.rotate(Vector3.UP, -PI/2)
	var left_crowd : Crowd = finish_line_instance.get_child(2)
	var right_crowd : Crowd = finish_line_instance.get_child(3)
	left_crowd.on_race = true
	left_crowd.visible = true
	right_crowd.on_race = true
	right_crowd.visible = true
	_end_race_x_pos = finish_line_instance.position.x
	race_length = _end_race_x_pos - _race_start_x

func _border_generation() -> void:
	for i in range(race_length):
		var x = i + _race_start_x
		_spawn_border(x, -race_width/2 - 1)  # left border
		_spawn_border(x,  race_width/2 + 1)  # right border

func _spawn_border(x_pos: float, z_pos: float):
	var border = default_border_sample.instantiate()
	current_race_objects.append(border)
	border.position.x = x_pos
	border.position.z = z_pos
	add_child(border)


func _obstacle_generation() -> void:
	_depth_dist = _rng.randf_range(depth_dist_btw_object_range.x, depth_dist_btw_object_range.y)
	_current_x_pos += _depth_dist
	while _current_x_pos < race_length + _race_start_x:
		_obstacles_pos_and_scale(_current_x_pos, -race_width/2, race_width/2, 5)
		
		_depth_dist = _rng.randf_range(depth_dist_btw_object_range.x, depth_dist_btw_object_range.y)
		_current_x_pos += _depth_dist

func _obstacles_pos_and_scale(pos_x: float, left_border_pos, right_border_pos, nb_obs)->void:
	if (nb_obs == 0):
		return 
	var obstacle: Node3D = obstacle_sample.instantiate()
	current_race_objects.append(obstacle)
	obstacle.position.x = pos_x
	while true:
		var pos_z = _rng.randf_range(left_border_pos, right_border_pos)
		var size_z = _rng.randf_range(object_size_range.x, object_size_range.y)

		var in_race_space = pos_z - size_z/2 > left_border_pos and pos_z + size_z/2 < right_border_pos
		var enough_space = pos_z - size_z/2 - left_border_pos > min_passage_size or pos_z + size_z/2 - right_border_pos > min_passage_size

		if in_race_space and enough_space:
			obstacle.position.z = pos_z
			obstacle.scale.z = size_z
			break
	add_child(obstacle)

	var dist_right = right_border_pos - (obstacle.position.z + obstacle.scale.z/2)
	var dist_left = (obstacle.position.z - obstacle.scale.z/2) - left_border_pos

	if (dist_right > dist_left):
		if dist_right > min_passage_size + object_size_range.x:
			_obstacles_pos_and_scale(pos_x, obstacle.position.z + obstacle.scale.z/2, right_border_pos, nb_obs - 1)
	else:
		if dist_left > min_passage_size + object_size_range.x:
			_obstacles_pos_and_scale(pos_x, left_border_pos, obstacle.position.z - obstacle.scale.z/2, nb_obs - 1)

func _destroy_current_race_objects()->void:
	for i in range(current_race_objects.size() - 1, -1, -1):
		current_race_objects[i].queue_free()
		current_race_objects.remove_at(i)

func _change_current_parameters() -> void:
	current_race_data = race_data[current_race_data_indice]
	race_length = current_race_data.race_length
	race_width = current_race_data.race_width
	object_size_range = current_race_data.object_size_range
	depth_dist_btw_object_range = current_race_data.depth_dist_btw_object_range
	horiz_dist_btw_object_range = current_race_data.horiz_dist_btw_object_range
	min_passage_size = current_race_data.min_passage_size
	if current_race_data.border_sample == null:
		current_race_data.border_sample = default_border_sample
	if current_race_data.obstacle_sample == null:
		current_race_data.obstacle_sample = default_obstacle_sample

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player = body
