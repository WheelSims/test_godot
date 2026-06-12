class_name ObstacleRaceGenerator
extends Node3D

## Distance between levels
@export var end_offset_to_restart: float = 10

## List of races and their parameters
@export var races_data: Array[RaceData]
@export var obstacle_infos: Array[ObjectInfo]
@export var transparent_wall_infos: Array[ObjectInfo]
@export var opaque_wall_infos: Array[ObjectInfo]
@export var finish_line_with_decor: PackedScene
@export var finish_line: PackedScene
@export var start_line: PackedScene
@export var border_info: ObjectInfo
@export var challenge_area: PackedScene

var current_tiles: Array[Node3D] = []

var current_race_data_indice := 0
var current_race_data: RaceData

var _rng = RandomNumberGenerator.new()

## A dictionary with object infos as key and their potential sizes as values.
## The selected objects are the obstacles used on the current challenge generation.
var _quanted_race_obst_sizes: Dictionary = {}
## The highest value of obstacle x_size on current challenge.
## It allows to calculate the x_size of the challenge area
var _x_size_chal: float = 0

## _current_x_pos progresses as the levels build up (with [method challenge_generation])
var _current_x_pos: float = 0

@onready var game_script: ObstacleRaceGame = $game


func _ready() -> void:
	_validate_config()
	_rng.randomize()
	game_script.init(races_data)
	for i in range(races_data.size()):
		_level_generation()


## Launch the level generation: arches, borders and obstacles/walls.
func _level_generation() -> void:
	current_race_data = races_data[current_race_data_indice]
	current_race_data.race_start_x = _current_x_pos
	_challenges_generation()
	_arches_generation()
	_border_generation()
	current_race_data_indice += 1
	_current_x_pos += end_offset_to_restart


## Generate start and end lines with crowds.
func _arches_generation() -> void:
	if current_race_data_indice > 0:
		_arch_generation(start_line, true)
	else:
		_area_generation(current_race_data.race_start_x, game_script.on_race_entered)
	if current_race_data_indice == races_data.size() - 1:
		_arch_generation(finish_line_with_decor, false)
	else:
		_arch_generation(finish_line, false)
	current_race_data.race_length = (
		current_race_data.end_race_x_pos - current_race_data.race_start_x
	)


func _arch_generation(line: PackedScene, is_start_line: bool) -> void:
	var line_instance := line.instantiate()
	add_child(line_instance)
	line_instance.rotate(Vector3.UP, -PI / 2)
	var left_crowd: Crowd = line_instance.get_child(0)
	var right_crowd: Crowd = line_instance.get_child(1)
	var crowd_list: Array[Crowd] = [left_crowd, right_crowd]
	left_crowd.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	left_crowd.set_deferred("visible", false)
	right_crowd.set_deferred("process_mode", PROCESS_MODE_DISABLED)
	right_crowd.set_deferred("visible", false)
	if is_start_line:
		races_data[current_race_data_indice].start_crowds = crowd_list
		line_instance.position.x = current_race_data.race_start_x
		_area_generation(current_race_data.race_start_x, game_script.on_race_entered)
	else:
		current_race_data.final_crowds = crowd_list
		line_instance.position.x = _current_x_pos
		current_race_data.end_race_x_pos = line_instance.position.x
		_area_generation(_current_x_pos, game_script.on_race_exited)


## Generate an area3d with the
func _area_generation(
	position_x: float,
	method_connected_to_area_entered: Callable = Callable(),
	method_connected_to_area_exited: Callable = Callable(),
	scale_x: float = 0
) -> void:
	var area: Area3D = challenge_area.instantiate()
	area.position.x = position_x
	area.scale.z = current_race_data.race_width
	add_child(area)
	if scale_x > 0:
		area.scale.x = scale_x
	if method_connected_to_area_entered.is_valid():
		area.area_entered.connect(method_connected_to_area_entered.bind(area))
	if method_connected_to_area_exited.is_valid():
		area.area_exited.connect(method_connected_to_area_exited.bind(area))


## Generate border of race and the transition to the next race
func _border_generation() -> void:
	var cursor_x: float = current_race_data.race_start_x
	var border_width = border_info.local_scale.z
	var l_first_point = Vector3(cursor_x, 0, -current_race_data.race_width / 2 - border_width / 2)
	var r_first_point = Vector3(cursor_x, 0, current_race_data.race_width / 2 + border_width / 2)
	var l_last_point = Vector3(
		cursor_x + current_race_data.race_length,
		0,
		-current_race_data.race_width / 2 - border_width / 2
	)
	var r_last_point = Vector3(
		cursor_x + current_race_data.race_length,
		0,
		current_race_data.race_width / 2 + border_width / 2
	)
	_line_border_generation(l_first_point, l_last_point)
	cursor_x += _line_border_generation(r_first_point, r_last_point)

	#Border generation for the transition on the next race
	if current_race_data_indice >= races_data.size() - 1:
		return
	l_first_point = Vector3(cursor_x, 0, -current_race_data.race_width / 2 - border_width / 2)
	r_first_point = Vector3(cursor_x, 0, current_race_data.race_width / 2 + border_width / 2)
	l_last_point = Vector3(
		cursor_x + end_offset_to_restart,
		0,
		-races_data[current_race_data_indice + 1].race_width / 2 - border_width / 2
	)
	r_last_point = Vector3(
		cursor_x + end_offset_to_restart,
		0,
		races_data[current_race_data_indice + 1].race_width / 2 + border_width / 2
	)
	_line_border_generation(l_first_point, l_last_point)
	_line_border_generation(r_first_point, r_last_point)


func _line_border_generation(first_point: Vector3, last_point: Vector3) -> float:
	var border_length = border_info.local_scale.x
	var direction = last_point - first_point
	var distance = direction.length()
	var cursor = 0.0
	var cursor_pos = first_point
	var the_rotation = rad_to_deg(Vector3.RIGHT.signed_angle_to(direction, Vector3.UP))
	while cursor < distance:
		cursor_pos += direction.normalized() * border_length / 2
		_spawn_border(cursor_pos.x, cursor_pos.z, border_info.scene, the_rotation)  # left border
		_spawn_border(cursor_pos.x, cursor_pos.z, border_info.scene, the_rotation)  # right border
		cursor += border_length
		cursor_pos += direction.normalized() * border_length / 2
	return cursor


## Spawn one border at the given position. X/Z is the position in the length/width axis.
## border_sample must be a cube of size 1 for now.
func _spawn_border(x_pos: float, z_pos: float, border_sample: PackedScene, y_rot: float = 0.0):
	var border = border_sample.instantiate()
	border.position.x = x_pos
	border.position.z = z_pos
	border.rotation_degrees.y += 90 + y_rot
	add_child(border)
	border.area3d.area_entered.connect(game_script.on_obstacle_collision.bind(border.area3d))


## A challenge is a line of obstacles or walls.
## _challenges_generation decides for every challenge if it is a line of transparent walls, opaque
## walls, or obstacles. In the same time, it executes _challenge_builder that generate one
## challenge.
func _challenges_generation() -> void:
	current_race_data.challenge_gap = _rng.randf_range(
		current_race_data.challenge_gap_range.x, current_race_data.challenge_gap_range.y
	)
	_current_x_pos += current_race_data.challenge_gap
	while _current_x_pos < current_race_data.race_length + current_race_data.race_start_x:
		_x_size_chal = 0
		if _rng.randf() < current_race_data.obstacle_opening_prob:
			# Obstacle case
			_challenge_builder(_current_x_pos, 0.25, obstacle_infos.pick_random())
		else:
			if _rng.randf() < current_race_data.transparent_op_wall_prob:
				# Transparant wall case
				var object_info: ObjectInfo = transparent_wall_infos.pick_random()
				_challenge_builder(
					_current_x_pos,
					object_info.get_z_sizes().values()[0],
					transparent_wall_infos.pick_random()
				)
			else:
				# Opaque wall case
				_challenge_builder(_current_x_pos, 0.25, opaque_wall_infos.pick_random())
		_area_generation(
			_current_x_pos,
			game_script.on_challenge_area_entered,
			game_script.on_challenge_area_exited,
			_x_size_chal
		)
		_current_x_pos += current_race_data.challenge_gap


## A challenge is a line of obstacles or walls.
## Depending on the object_info, _challenge_builder generates a line of transparent walls, opaque
## walls, or obstacles. The nature of the quantum depends on the object_info.type.
## UnitWall => quantum = object_info.z_size.
## ScalableWall and obstacle => the size is always a |n * quantum| number.
func _challenge_builder(pos_x: float, quantum: float, object_info: ObjectInfo) -> void:
	var total_length = int(current_race_data.race_width / quantum)
	var size_range: Vector2 = (
		current_race_data.obst_size_range
		if object_info.type == WorldScaleCalculator.ObjectType.OBSTACLE
		else current_race_data.wall_size_range
	)
	var gap_range: Vector2 = (
		current_race_data.obst_gap_range
		if object_info.type == WorldScaleCalculator.ObjectType.OBSTACLE
		else current_race_data.opening_size_range
	)

	var wall_min: int = int(size_range.x / quantum)
	var wall_max: int = int(size_range.y / quantum)
	var open_min: int = int(gap_range.x / quantum)
	var open_max: int = int(gap_range.y / quantum)

	if object_info.type == WorldScaleCalculator.ObjectType.UNIT_WALL:
		wall_min += 1
		open_min += 1

	var length_obst_list: Array[int] = []
	if object_info.type == WorldScaleCalculator.ObjectType.OBSTACLE:
		length_obst_list = _quant_race_obst_sizes(quantum)
		if length_obst_list.size() > 0:
			wall_min = length_obst_list.front()
			wall_max = length_obst_list.back()
		else:
			push_error("List of obstacle length empty")

	var generator := SegmentGenerator.new()
	var segments: Array[Segment] = generator.generate_segments(
		total_length, wall_min, wall_max, open_min, open_max, _rng, length_obst_list
	)
	#generator.print_segments(segments)
	_segments_to_objects(object_info, segments, quantum, pos_x)


## With a list of segments, call the right spawn method depending on object_info.type
func _segments_to_objects(
	object_info: ObjectInfo, segments: Array[Segment], quantum: float, pos_x: float
) -> void:
	var scale_z: float
	var cursor_z: float = -current_race_data.race_width / 2
	for i in range(segments.size()):
		scale_z = segments[i].length * quantum
		cursor_z += scale_z / 2
		if segments[i].type == Segment.SegmentType.WALL:
			if object_info.type == WorldScaleCalculator.ObjectType.OBSTACLE:
				_obstacle_spawn(pos_x, cursor_z, scale_z)
			elif object_info.type == WorldScaleCalculator.ObjectType.SCALABLE_WALL:
				_scalable_object_spawn(pos_x, cursor_z, scale_z, object_info)
			elif object_info.type == WorldScaleCalculator.ObjectType.UNIT_WALL:
				_unit_object_spawn(pos_x, cursor_z - scale_z / 2, segments[i].length, object_info)
		cursor_z += scale_z / 2


## Obstacle_spawn doesn't need a PackedScene argument because it takes randomly in the
## _quanted_race_obst_sizes dictionary.
func _obstacle_spawn(pos_x: float, pos_z: float, scale_z: float) -> void:
	var obstacle: ObjectInfo = MathUtils.find_random_key(_quanted_race_obst_sizes, scale_z, _rng)
	if obstacle == null:
		push_error("Didn't find an obstacle for that scale: %.3f" % scale_z)
		return
	var instance := obstacle.scene.instantiate()
	var list: Array = obstacle.get_z_sizes().values()
	var original_scale = MathUtils.clother_number(list, scale_z)
	var y_rotation = MathUtils.find_random_key(obstacle.get_z_sizes(), original_scale, _rng)
	var obst_x_size = obstacle.sizes[y_rotation].x
	if obst_x_size > _x_size_chal:
		_x_size_chal = obst_x_size
	instance.position.x = pos_x
	if y_rotation != null:
		instance.visual_instance.rotation_degrees.y = y_rotation
	instance.position.z = pos_z
	instance.scale_from_real_size(scale_z, original_scale)
	add_child(instance)
	instance.area3d.area_entered.connect(game_script.on_obstacle_collision.bind(instance.area3d))


func _scalable_object_spawn(
	pos_x: float, pos_z: float, scale_z: float, obj_info: ObjectInfo
) -> void:
	var obstacle: WorldScaleCalculator = obj_info.scene.instantiate()
	var obst_x_size = obj_info.sizes.values()[0].x
	if obst_x_size > _x_size_chal:
		_x_size_chal = obst_x_size
	if obstacle == null:
		push_error("an obstacle didn't instantiate")
		return
	obstacle.position.x = pos_x
	obstacle.position.z = pos_z
	obstacle.scale.z = scale_z
	add_child(obstacle)
	obstacle.area3d.area_entered.connect(game_script.on_obstacle_collision.bind(obstacle.area3d))


func _unit_object_spawn(
	pos_x: float, cursor_z: float, segment_length: int, object_info: ObjectInfo
) -> void:
	var obst_x_size = object_info.sizes.values()[0].x
	if obst_x_size > _x_size_chal:
		_x_size_chal = obst_x_size
	var the_remainder = fmod(current_race_data.race_width, object_info.get_z_sizes().values()[0])
	for i in range(0, segment_length):
		var instance: Node3D = object_info.scene.instantiate()
		instance.position.x = pos_x
		instance.position.z = (
			cursor_z + (i + 0.5) * object_info.get_z_sizes().values()[0] + the_remainder
		)
		add_child(instance)
		instance.area3d.area_entered.connect(
			game_script.on_obstacle_collision.bind(instance.area3d)
		)


## Select obstacles in the obstacle_size_range.
## Make a list of their sizes quotient (1.75 with quantum = 0.25 => 7) with
## [method MathUtils.clother_xquantum]. Returns the list.
## Also clear and write [member _quanted_race_obst_sizes].
func _quant_race_obst_sizes(quantum: float) -> Array[int]:
	_quanted_race_obst_sizes.clear()
	var list: Array[int] = []
	for obst_info in obstacle_infos:
		var obstacles_sizes = obst_info.get_z_sizes()
		var list_lengths: Array[float] = []
		for length in obstacles_sizes.values():
			var n := MathUtils.clother_xquantum(quantum, length)
			if (
				n * quantum < current_race_data.obst_size_range.x
				or n * quantum > current_race_data.obst_size_range.y
			):
				continue
			list_lengths.append(n * quantum)
			if not n in list:
				list.append(n)
		_quanted_race_obst_sizes[obst_info] = list_lengths
	list.sort()
	return list


func _validate_config() -> void:
	assert(is_instance_valid(finish_line), "finish_line PackedScene is null or invalid")
	assert(is_instance_valid(start_line), "start_line PackedScene is null or invalid")
	assert(is_instance_valid(border_info), "border_info is null or invalid")
	_validate_resource_array(races_data, "races_data")
	_validate_resource_array(obstacle_infos, "obstacle_infos")
	_validate_resource_array(transparent_wall_infos, "transparent_wall_infos")
	_validate_resource_array(opaque_wall_infos, "opaque_wall_infos")


func _validate_resource_array(array: Array, r_name: String) -> void:
	assert(not array.is_empty(), "%s cannot be empty" % r_name)
	for i in array.size():
		if array[i] is ObjectInfo:
			assert(array[i].is_valid(), "%s contains invalid element at index %d" % [r_name, i])
		else:
			assert(
				is_instance_valid(array[i]), "%s contains invalid element at index %d" % [r_name, i]
			)
