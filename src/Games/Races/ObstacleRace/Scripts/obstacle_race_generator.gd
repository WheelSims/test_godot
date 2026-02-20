extends Node3D

var player: Node3D
# Storage to delete current objects if needed
var current_race_objects: Array[Node3D] = []
## Distance between levels
@export var end_offset_to_restart: float
## List of races and their parameters
@export var race_data: Array[RaceData]
var current_race_data_indice := 0
var current_race_data
var default_border_samples: Array[PackedScene]
var default_obstacle_infos: Array[ObjectInfo]
@export var border_samples: Array[PackedScene]
@export var obstacle_infos: Array[ObjectInfo]
@export var transparent_wall_infos: Array[ObjectInfo]
@export var opaque_wall_infos: Array[ObjectInfo]
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
var _remainder: float
var _quanted_race_obst_sizes: Dictionary = {}

# _race_start_x and _end_race_x_pos reset at every new level
var _race_start_x : float = 0
var _end_race_x_pos : float = 0
# _current_x_pos progresses as the levels build up
var _current_x_pos : float = 0
# _start_ground_tile_x_pos is the position where the ground starts to be built for every level. Not the same same than _race_start_x
var _start_ground_tile_x_pos : float = 0

func _ready() -> void:
	_rng.randomize()
	default_border_samples = border_samples
	default_obstacle_infos = obstacle_infos
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
	
func _quant_race_obst_sizes(quantum:float)->Array[int]:
	var list: Array[int] = []
	for obst_info in obstacle_infos:
		var _obstacles_sizes = obst_info.z_sizes
		var list_lengths: Array[float] = []
		for length in _obstacles_sizes.values():
			var n := MathUtils.clother_xquantum(quantum, length)
			if n*quantum < obst_size_range.x or n*quantum > obst_size_range.y:
				continue
			list_lengths.append(n*quantum)
			if not n in list:
				list.append(n)
		_quanted_race_obst_sizes[obst_info] = list_lengths
	list.sort()
	return list

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
	var border_sample : PackedScene = default_border_samples.pick_random()
	for i in range(race_length):
		var x = i + _race_start_x
		_spawn_border(x, -race_width/2 - 0.5, border_sample)  # left border
		_spawn_border(x,  race_width/2 + 0.5, border_sample)  # right border

func _spawn_border(x_pos: float, z_pos: float, border_sample: PackedScene):
	var border = border_sample.instantiate()
	current_race_objects.append(border)
	border.position.x = x_pos
	border.position.z = z_pos
	add_child(border)

func _challenge_generation() -> void:
	_depth_dist = _rng.randf_range(depth_dist_btw_challenge_range.x, depth_dist_btw_challenge_range.y)
	_current_x_pos += _depth_dist
	while _current_x_pos < race_length + _race_start_x:
		if _rng.randf() < obstacle_opening_prob:
			# Obstacle case
			_object_builder(_current_x_pos, 0.25, obstacle_infos.pick_random())
		else:
			if _rng.randf() < transparent_op_wall_prob: 
				# Transparant wall case
				var object_info: ObjectInfo = transparent_wall_infos.pick_random()
				_object_builder(_current_x_pos, object_info.z_sizes.values()[0], transparent_wall_infos.pick_random())
			else:
				# Opaque wall case
				_object_builder(_current_x_pos, 0.25,  opaque_wall_infos.pick_random())
		#_depth_dist = _rng.randf_range(depth_dist_btw_challenge_range.x, depth_dist_btw_challenge_range.y)
		_current_x_pos += _depth_dist
		
func _object_builder(pos_x: float, quantum: float,  object_info: ObjectInfo)->void:
	var total_length = int(race_width / quantum)
	var size_range: Vector2 = obst_size_range if object_info.type == WorldScaleCalculator.ObjectType.Obstacle else wall_size_range
	var gap_range: Vector2 = horiz_dist_btw_obst_range if object_info.type == WorldScaleCalculator.ObjectType.Obstacle else opening_size_range
	
	var wall_min: int = int(size_range.x / quantum)
	var wall_max: int = int(size_range.y / quantum)
	var open_min: int = int(gap_range.x / quantum)
	var open_max: int = int(gap_range.y / quantum)
	
	if object_info.type == WorldScaleCalculator.ObjectType.UnitWall:
		wall_min += 1
		open_min += 1
	
	var length_obst_list: Array[int] = []
	if object_info.type == WorldScaleCalculator.ObjectType.Obstacle:
		length_obst_list = _quant_race_obst_sizes(quantum)
		if length_obst_list.size() > 0:
			wall_min = length_obst_list.front()
			wall_max = length_obst_list.back()
		else:
			push_error("List of obstacle length empty")
		
	var generator := SegmentGenerator.new()
	var segments : Array[Segment] = generator.generate_segments( total_length,
		wall_min,
		wall_max,
		open_min,
		open_max,
		_rng,
		length_obst_list
	)
	generator.print_segments(segments)
	
	_segments_to_objects(object_info, segments, quantum, pos_x)
		
func _segments_to_objects(object_info: ObjectInfo, segments: Array[Segment], quantum: float, pos_x: float)->void:
	var pos_z: float
	var scale_z: float
	var first_pos_z: float
	var last_pos_z: float
	var cursor_z: float = -race_width/2
	for i in range(segments.size()):
		scale_z = segments[i].length * quantum
		cursor_z += scale_z/2
		if segments[i].type == Segment.SegmentType.WALL:
			if object_info.type == WorldScaleCalculator.ObjectType.Obstacle:  _obstacle_spawn(pos_x, cursor_z, scale_z)
			elif object_info.type == WorldScaleCalculator.ObjectType.ScalableWall: _scalable_object_spawn(pos_x, cursor_z, scale_z, object_info.scene)
			elif object_info.type == WorldScaleCalculator.ObjectType.UnitWall: _unit_object_spawn(pos_x, cursor_z - scale_z/2, segments[i].length, object_info)
		cursor_z += scale_z/2
		
func _obstacle_spawn(pos_x: float, pos_z: float, scale_z: float)->void:
	var obstacle: ObjectInfo = MathUtils.find_random_key(_quanted_race_obst_sizes, scale_z, _rng)
	if obstacle == null:
		push_error("Didn't find an obstacle for that scale: %.3f" % scale_z)
		return
	var instance := obstacle.scene.instantiate()
	var list: Array = obstacle.z_sizes.values()
	var original_scale = MathUtils.clother_number(list, scale_z)
	var rotation = MathUtils.find_random_key(obstacle.z_sizes, original_scale, _rng)
	
	current_race_objects.append(instance)
	instance.position.x = pos_x
	if rotation != null:
		instance.visual_instance.rotation_degrees.y = rotation
	instance.position.z = pos_z
	instance.scale_from_real_size(scale_z, original_scale)
	add_child(instance)
	
func _scalable_object_spawn(pos_x: float, pos_z: float, scale_z: float, obj_sample: PackedScene)->void:
	var obstacle: Node3D = obj_sample.instantiate()
	if obstacle == null:
		push_error("an obstacle didn't instantiate")
		return
	current_race_objects.append(obstacle)
	obstacle.position.x = pos_x
	obstacle.position.z = pos_z
	obstacle.scale.z = scale_z
	add_child(obstacle)
	
func _unit_object_spawn(pos_x: float, cursor_z: float, segment_length: int, object_info: ObjectInfo)->void:
	_remainder = fmod(race_width, object_info.z_sizes.values()[0]) ## _remainder
	for i in range(0, segment_length):
		var instance: Node3D = object_info.scene.instantiate()
		instance.position.x = pos_x
		instance.position.z = cursor_z + (i + 1/2) * object_info.z_sizes.values()[0] + _remainder
		add_child(instance)

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
	if current_race_data.border_samples == null:
		current_race_data.border_samples = default_border_samples
	if current_race_data.obstacle_infos == null:
		current_race_data.obstacle_infos = default_obstacle_infos

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		player = body
