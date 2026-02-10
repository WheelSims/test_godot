extends Node3D

var player: Node3D
# Storage to delete current objects if needed
var current_race_objects: Array[Node3D] = []
@export var restart_pos: Node3D
## Distance between levels
@export var end_offset_to_restart: float
## List of races and their parameters
@export var race_data: Array[RaceData]
var current_race_data_indice := 0
var current_race_data
var default_border_sample: PackedScene
var default_obstacle_sample: PackedScene
@export var border_sample: PackedScene
@export var obstacle_sample: PackedScene
@export var fence_sample: PackedScene
@export var brick_sample: PackedScene
@export var finish_line: PackedScene
var finish_line_instance : Node3D
@export var start_line: PackedScene
var start_line_instance : Node3D
@export var ground_tile: PackedScene
var tile_length : float  #the tile is a square
var current_tiles: Array[Node3D] = []

#Race parameters
var race_length: int = 100
var race_width: float = 10
var obst_size_range: Vector2 = Vector2(0.5,3)
var depth_dist_btw_challenge_range: Vector2 = Vector2(5,20)
var horiz_dist_btw_obst_range: Vector2 = Vector2(3,5)
## min and max of openings size
var opening_size_range: Vector2 = Vector2(3,5)
## min and max of walls size between openings
var wall_size_range: Vector2 = Vector2(4, 7)
## probability of having obstacles (0) or openings (1) with walls
var obstacle_opening_prob: float
## probability of having transparent (0) walls or not (1) (fence or brick walls)
var transparent_op_wall_prob: float

var _rng = RandomNumberGenerator.new()
var _depth_dist: float
var _horiz_dist: float
var _object_size: float
var remainder: float

# _race_start_x and _end_race_x_pos reset at every new level
var _race_start_x : float = 0
var _end_race_x_pos : float = 0
# _current_x_pos progresses as the levels build up
var _current_x_pos : float = 0
# _start_ground_tile_x_pos is the position where the ground starts to be built for every level. Not the same same than _race_start_x
var _start_ground_tile_x_pos : float = 0
## Opening = no wall, transp = you can see across the wall (ex: fence), untransp = you can't see across it (ex: brickwall)
enum WallNature {opening, transp, untransp}
class Wall:
	var wall_nature: WallNature
	var node: Node3D
	var z: float

var walls_on_current_challenge: Array[Wall] = []

func _ready() -> void:
	_rng.randomize()
	default_border_sample = border_sample
	default_obstacle_sample = obstacle_sample
	var ground_tile : Node3D = ground_tile.instantiate()
	var mesh : PlaneMesh = ground_tile.mesh
	tile_length = mesh.size.x
	ground_tile.queue_free()
	if race_data.size()>0:
		current_race_data = race_data[0]
		_change_current_parameters()
	_start_ground_tile_x_pos = _current_x_pos
	_challenge_generation()
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
	_challenge_generation()
	_arches_generation()
	_border_generation()
	_ground_generation()

func _ground_generation():
	var x_count = ceil((race_length + end_offset_to_restart) / tile_length)
	var z_count = ceil(race_width / tile_length) + 1

	for i in range(x_count):
		for j in range(z_count):
			var tile: Node3D = ground_tile.instantiate()
			tile.position = Vector3(
				_start_ground_tile_x_pos + i * tile_length + tile_length / 2.0,
				0,
				j * tile_length - race_width / 2
			)
			add_child(tile)
			current_tiles.append(tile)
	_start_ground_tile_x_pos += + x_count * tile_length
	
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
		_spawn_border(x, -race_width/2 - 0.5)  # left border
		_spawn_border(x,  race_width/2 + 0.5)  # right border

func _spawn_border(x_pos: float, z_pos: float):
	var border = default_border_sample.instantiate()
	current_race_objects.append(border)
	border.position.x = x_pos
	border.position.z = z_pos
	add_child(border)

func _challenge_generation() -> void:
	_depth_dist = _rng.randf_range(depth_dist_btw_challenge_range.x, depth_dist_btw_challenge_range.y)
	_current_x_pos += _depth_dist
	while _current_x_pos < race_length + _race_start_x:
		walls_on_current_challenge.clear()
		if _rng.randf() < obstacle_opening_prob:
			_object_builder(_current_x_pos, 0.25, true, false)
		else:
			if _rng.randf() < transparent_op_wall_prob:
				#fence is already scaled
				_object_builder(_current_x_pos, 0, false, true)
			else:
				_object_builder(_current_x_pos, 0.25, false, false)
		#_depth_dist = _rng.randf_range(depth_dist_btw_challenge_range.x, depth_dist_btw_challenge_range.y)
		_current_x_pos += _depth_dist
		
func _object_builder(pos_x: float, quantum: float, is_obst: bool, already_scaled: bool)->void:
	var total_length: float
	if already_scaled:
		var wall: WorldScaleCalculator = fence_sample.instantiate()
		quantum = wall.get_world_scale().x
		_wall_builder(pos_x, -race_width/2, race_width/2, fence_sample, wall.get_world_scale().x)
		total_length = walls_on_current_challenge.size()
	else:
		total_length = int(race_width / quantum)
	
	var wall_min: float = int(obst_size_range.x / quantum) if is_obst else int(wall_size_range.x / quantum)
	var wall_max: float = int(obst_size_range.y / quantum) if is_obst else int(wall_size_range.y / quantum)
	if already_scaled: 
		wall_min+=1
		wall_max+=1
	var open_min: float = int(horiz_dist_btw_obst_range.x / quantum) if is_obst else int(opening_size_range.x / quantum)
	var open_max: float = int(horiz_dist_btw_obst_range.y / quantum) if is_obst else int(opening_size_range.y / quantum)
	
	var generator := SegmentGenerator.new()
	var segments : Array[Segment]= generator.generate_segments(
		total_length,
		wall_min,
		wall_max,
		open_min,
		open_max,
		_rng
	)
	generator.print_segments(segments)
	
	if !already_scaled:
		var object_sample: PackedScene = obstacle_sample if is_obst else brick_sample
		_segments_to_real_obsts(segments, quantum, pos_x, object_sample)
	else:
		_segments_to_real_unit_walls(segments)

func _segments_to_real_obsts(segments: Array[Segment], quantum: float, pos_x: float, obj_sample: PackedScene)->void:
	var pos_z: float
	var scale_z: float 
	var first_pos_z: float
	var last_pos_z: float
	var cursor_z: float = -race_width/2
	for i in range(segments.size()):
		cursor_z += quantum * segments[i].length/2
		if segments[i].type == Segment.SegmentType.WALL:
			scale_z = segments[i].length * quantum
			_obstacle_spawn(pos_x, cursor_z, scale_z, obj_sample)
		cursor_z += quantum * segments[i].length/2
	
func _obstacle_spawn(pos_x: float, pos_z: float, scale_z: float, obj_sample: PackedScene)->void:
	var obstacle: Node3D = obj_sample.instantiate()
	current_race_objects.append(obstacle)
	obstacle.position.x = pos_x
	obstacle.position.z = pos_z
	obstacle.scale.z = scale_z
	add_child(obstacle)
		
func _segments_to_real_unit_walls(segments: Array[Segment])->void:
	var cursor_i: int = 0
	for i in range (segments.size()):
		var segment: Segment = segments[i]
		if segment.type == Segment.SegmentType.WALL:
			cursor_i += segment.length
		elif segment.type == Segment.SegmentType.OPENING:
			var cursor_i_for = cursor_i
			for j in range(cursor_i_for, cursor_i_for + segment.length):
				cursor_i += 1
				var wall : Wall = walls_on_current_challenge[j]
				wall.wall_nature = WallNature.opening
				wall.node.queue_free()
		
	
func _wall_builder(pos_x:float, left_border_pos: float, right_border_pos: float, wall: PackedScene, wall_size_z: float)->void:
	var wall_info: Wall
	remainder = fmod(race_width, wall_size_z) ## remainder
	var cursor_z: float = left_border_pos + wall_size_z/2 - remainder/2
	
	while(cursor_z < right_border_pos + wall_size_z / 2):
		var wall_instance = wall.instantiate()
		wall_instance.position.z = cursor_z
		wall_instance.position.x = pos_x
		wall_info = Wall.new()
		wall_info.wall_nature = WallNature.transp
		wall_info.node = wall_instance
		wall_info.z = cursor_z
		walls_on_current_challenge.append(wall_info)
		add_child(wall_instance)
		cursor_z += wall_size_z
	_sort_wall_list()
	
func _sort_wall_list()->void:
	var min: float = INF
	var min_wall: Wall
	var list: Array[Wall] = []
	var size = walls_on_current_challenge.size()
	while list.size() != size:
		min = INF
		for wall in walls_on_current_challenge:
			if wall.z < min:
				min = wall.z
				min_wall = wall
		list.append(min_wall)
		walls_on_current_challenge.erase(min_wall)
	walls_on_current_challenge = list

func _destroy_current_race_objects()->void:
	for i in range(current_race_objects.size() - 1, -1, -1):
		current_race_objects[i].queue_free()
		current_race_objects.remove_at(i)

func _change_current_parameters() -> void:
	current_race_data = race_data[current_race_data_indice]
	race_length = current_race_data.race_length
	race_width = current_race_data.race_width
	obst_size_range = current_race_data.obst_size_range
	depth_dist_btw_challenge_range = current_race_data.depth_dist_btw_challenge_range
	horiz_dist_btw_obst_range = current_race_data.horiz_dist_btw_obst_range
	opening_size_range = current_race_data.opening_size_range
	wall_size_range = current_race_data.wall_size_range
	obstacle_opening_prob = current_race_data.obstacle_opening_prob
	transparent_op_wall_prob = current_race_data.transparent_op_wall_prob
	if current_race_data.border_sample == null:
		current_race_data.border_sample = default_border_sample
	if current_race_data.obstacle_sample == null:
		current_race_data.obstacle_sample = default_obstacle_sample

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player = body
