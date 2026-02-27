extends Node3D

var player: Node3D
## Distance between levels
@export var end_offset_to_restart: float = 10
## List of races and their parameters
@export var races_data: Array[RaceData]
@export var obstacle_infos: Array[ObjectInfo]
@export var transparent_wall_infos: Array[ObjectInfo]
@export var opaque_wall_infos: Array[ObjectInfo]
@export var ground_tile_info: ObjectInfo
@export var finish_line: PackedScene
@export var start_line: PackedScene
@export var border_samples: Array[PackedScene]
var current_tiles: Array[Node3D] = []

var _rng = RandomNumberGenerator.new()
var current_race_data_indice := 0
var current_race_data: RaceData
var _depth_dist: float
var _quanted_race_obst_sizes: Dictionary = {}

# _race_start_x and _end_race_x_pos reset at every new level
var _race_start_x : float = 0
var _end_race_x_pos : float = 0
# _current_x_pos progresses as the levels build up
var _current_x_pos : float = 0
# _start_ground_tile_x_pos is the position where the ground starts to be built for every level. Not the same same than _race_start_x
var _start_ground_tile_x_pos : float = 0

func _ready() -> void:
	_validate_config()
	_rng.randomize()
	for i in range(races_data.size()):
		_level_generation()

## Launch the level generation: arches, borders, ground and obstacles/walls.
func _level_generation()->void:
	current_race_data = races_data[current_race_data_indice]
	_challenges_generation()
	_arches_generation()
	_border_generation()
	_ground_generation()
	current_race_data_indice += 1
	_current_x_pos += end_offset_to_restart
	_race_start_x = _current_x_pos

## Generate the ground from tiles.
func _ground_generation():
	var tile_length: float = ground_tile_info.z_sizes.values()[0]
	var tile_scene: PackedScene = ground_tile_info.scene
	var x_count = ceil((current_race_data.race_length + end_offset_to_restart) / tile_length)
	var z_count = ceil(current_race_data.race_width / tile_length) + 1

	for i in range(x_count):
		for j in range(z_count):
			var tile: Node3D = tile_scene.instantiate()
			tile.position = Vector3(
				_start_ground_tile_x_pos + i * tile_length + tile_length / 2.0,
				0,
				j * tile_length - current_race_data.race_width / 2
			)
			add_child(tile)
			current_tiles.append(tile)
	_start_ground_tile_x_pos += + x_count * tile_length

## Generate start and end lines with crowds.
func _arches_generation()->void:
	if (current_race_data_indice>0):
		_arch_generation(start_line, true)
	_arch_generation(finish_line, false)
	current_race_data.race_length = _end_race_x_pos - _race_start_x
	
func _arch_generation(line: PackedScene, is_start_line: bool)->void:
	var line_instance:= line.instantiate()
	add_child(line_instance)
	line_instance.rotate(Vector3.UP, -PI/2)
	var left_crowd: Crowd = line_instance.get_child(0)
	var right_crowd: Crowd = line_instance.get_child(1)
	left_crowd.on_race = true
	right_crowd.on_race = true
	if is_start_line:
		line_instance.position.x = _race_start_x
	else:
		line_instance.position.x = _current_x_pos
		_end_race_x_pos = line_instance.position.x

## Generate border with border samples that must be cubes of size 1 for now.
func _border_generation() -> void:
	var border_sample : PackedScene = border_samples.pick_random()
	for i in range(current_race_data.race_length):
		var x = i + _race_start_x
		_spawn_border(x, -current_race_data.race_width/2 - 0.5, border_sample)  # left border
		_spawn_border(x,  current_race_data.race_width/2 + 0.5, border_sample)  # right border

## Spawn one border at the given position. X/Z is the position in the length/width axis.
## border_sample must be a cube of size 1 for now.
func _spawn_border(x_pos: float, z_pos: float, border_sample: PackedScene):
	var border = border_sample.instantiate()
	border.position.x = x_pos
	border.position.z = z_pos
	add_child(border)

## A challenge is a line of obstacles or walls.
## _challenges_generation decides for every challenge if it is a line of transparent walls, opaque walls, or obstacles.
## In the same time, it executes _challenge_builder that generate one challenge.
func _challenges_generation() -> void:
	_depth_dist = _rng.randf_range(current_race_data.challenge_gap_range.x, current_race_data.challenge_gap_range.y)
	_current_x_pos += _depth_dist
	while _current_x_pos < current_race_data.race_length + _race_start_x:
		if _rng.randf() < current_race_data.obstacle_opening_prob:
			# Obstacle case
			_challenge_builder(_current_x_pos, 0.25, obstacle_infos.pick_random())
		else:
			if _rng.randf() < current_race_data.transparent_op_wall_prob: 
				# Transparant wall case
				var object_info: ObjectInfo = transparent_wall_infos.pick_random()
				_challenge_builder(_current_x_pos, object_info.z_sizes.values()[0], transparent_wall_infos.pick_random())
			else:
				# Opaque wall case
				_challenge_builder(_current_x_pos, 0.25,  opaque_wall_infos.pick_random())
		#_depth_dist = _rng.randf_range(current_race_data.challenge_gap_range.x, current_race_data.challenge_gap_range.y)
		_current_x_pos += _depth_dist

## A challenge is a line of obstacles or walls.
## Depending on the object_info, _challenge_builder generates a line of transparent walls, opaque walls, or obstacles.
## The nature of the quantum depends on the object_info.type. 
## UnitWall => quantum = object_info.z_size. 
## ScalableWall and obstacle => the size is always a |n * quantum| number.
func _challenge_builder(pos_x: float, quantum: float,  object_info: ObjectInfo)->void:
	var total_length = int(current_race_data.race_width / quantum)
	var size_range: Vector2 = current_race_data.obst_size_range if object_info.type == WorldScaleCalculator.ObjectType.Obstacle else current_race_data.wall_size_range
	var gap_range: Vector2 = current_race_data.obst_gap_range if object_info.type == WorldScaleCalculator.ObjectType.Obstacle else current_race_data.opening_size_range
	
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
	#generator.print_segments(segments)
	_segments_to_objects(object_info, segments, quantum, pos_x)

## With a list of segments, call the right spawn method depending on object_info.type
func _segments_to_objects(object_info: ObjectInfo, segments: Array[Segment], quantum: float, pos_x: float)->void:
	var scale_z: float
	var cursor_z: float = -current_race_data.race_width/2
	for i in range(segments.size()):
		scale_z = segments[i].length * quantum
		cursor_z += scale_z/2
		if segments[i].type == Segment.SegmentType.WALL:
			if object_info.type == WorldScaleCalculator.ObjectType.Obstacle:  _obstacle_spawn(pos_x, cursor_z, scale_z)
			elif object_info.type == WorldScaleCalculator.ObjectType.ScalableWall: _scalable_object_spawn(pos_x, cursor_z, scale_z, object_info.scene)
			elif object_info.type == WorldScaleCalculator.ObjectType.UnitWall: _unit_object_spawn(pos_x, cursor_z - scale_z/2, segments[i].length, object_info)
		cursor_z += scale_z/2

## Obstacle_spawn doesn't need a PackedScene argument because it takes randomly in the _quanted_race_obst_sizes dictionary.
func _obstacle_spawn(pos_x: float, pos_z: float, scale_z: float)->void:
	var obstacle: ObjectInfo = MathUtils.find_random_key(_quanted_race_obst_sizes, scale_z, _rng)
	if obstacle == null:
		push_error("Didn't find an obstacle for that scale: %.3f" % scale_z)
		return
	var instance := obstacle.scene.instantiate()
	var list: Array = obstacle.z_sizes.values()
	var original_scale = MathUtils.clother_number(list, scale_z)
	var y_rotation = MathUtils.find_random_key(obstacle.z_sizes, original_scale, _rng)
	
	instance.position.x = pos_x
	if y_rotation != null:
		instance.visual_instance.rotation_degrees.y = y_rotation
	instance.position.z = pos_z
	instance.scale_from_real_size(scale_z, original_scale)
	add_child(instance)
	
func _scalable_object_spawn(pos_x: float, pos_z: float, scale_z: float, obj_sample: PackedScene)->void:
	var obstacle: Node3D = obj_sample.instantiate()
	if obstacle == null:
		push_error("an obstacle didn't instantiate")
		return
	obstacle.position.x = pos_x
	obstacle.position.z = pos_z
	obstacle.scale.z = scale_z
	add_child(obstacle)
	
func _unit_object_spawn(pos_x: float, cursor_z: float, segment_length: int, object_info: ObjectInfo)->void:
	var _remainder = fmod(current_race_data.race_width, object_info.z_sizes.values()[0]) ## _remainder
	for i in range(0, segment_length):
		var instance: Node3D = object_info.scene.instantiate()
		instance.position.x = pos_x
		instance.position.z = cursor_z + (i + 0.5) * object_info.z_sizes.values()[0] + _remainder
		add_child(instance)
		
func _quant_race_obst_sizes(quantum:float)->Array[int]:
	var list: Array[int] = []
	for obst_info in obstacle_infos:
		var _obstacles_sizes = obst_info.z_sizes
		var list_lengths: Array[float] = []
		for length in _obstacles_sizes.values():
			var n := MathUtils.clother_xquantum(quantum, length)
			if n*quantum < current_race_data.obst_size_range.x or n*quantum > current_race_data.obst_size_range.y:
				continue
			list_lengths.append(n*quantum)
			if not n in list:
				list.append(n)
		_quanted_race_obst_sizes[obst_info] = list_lengths
	list.sort()
	return list

func _validate_config() -> void:
	assert(is_instance_valid(ground_tile_info), "ground_tile_info is null or invalid")
	assert(is_instance_valid(finish_line), "finish_line PackedScene is null or invalid")
	assert(is_instance_valid(start_line), "start_line PackedScene is null or invalid")
	_validate_resource_array(races_data, "races_data")
	_validate_resource_array(obstacle_infos, "obstacle_infos")
	_validate_resource_array(transparent_wall_infos, "transparent_wall_infos")
	_validate_resource_array(opaque_wall_infos, "opaque_wall_infos")
	_validate_resource_array(border_samples, "border_samples")
	
func _validate_resource_array(array: Array, name: String) -> void:
	assert(not array.is_empty(), "%s cannot be empty" % name)
	for i in array.size():
		if (array[i] is ObjectInfo):
			assert(array[i].is_valid(), "%s contains invalid element at index %d" % [name, i])
		else:
			assert(is_instance_valid(array[i]), "%s contains invalid element at index %d" % [name, i])
