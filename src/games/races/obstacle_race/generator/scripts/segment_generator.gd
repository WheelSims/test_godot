class_name SegmentGenerator
extends RefCounted
## SegmentGenerator is used to generate a list of segments to describe a challenge in an obstacle race.

var _obstacle_sizes: Array[int]
var _opening_range: Array[int]


func generate_segments(
	total_length: int,
	wall_min: int,
	wall_max: int,
	open_min: int,
	open_max: int,
	rng: RandomNumberGenerator,
	obstacle_sizes: Array[int] = []
) -> Array[Segment]:
	if obstacle_sizes.size() == 0:
		return generate_wall_segments(total_length, wall_min, wall_max, open_min, open_max, rng)
	else:
		return _generate_obstacle_segments(total_length, open_min, open_max, rng, obstacle_sizes)


func generate_wall_segments(
	total_length: int,
	wall_min: int,
	wall_max: int,
	open_min: int,
	open_max: int,
	rng: RandomNumberGenerator,
) -> Array[Segment]:
	var segments: Array[Segment] = []
	var remaining := total_length
	var current_type := Segment.SegmentType.WALL
	if rng.randf() > 0.5:
		current_type = Segment.SegmentType.OPENING

	while remaining > 0:
		var min_len: int
		var max_len: int

		if current_type == Segment.SegmentType.WALL:
			min_len = wall_min
			max_len = wall_max
		else:
			min_len = open_min
			max_len = open_max

		# End case : last segment
		if remaining <= max_len:
			if remaining < min_len:
				printerr("No valid segmentation possible for last segment")
				return []
			segments.append(Segment.new(current_type, remaining))
			break

		var possible_lengths: Array[int] = []

		for l in range(min_len, max_len + 1):
			var r := remaining - l
			if _can_fill_rest(
				r,
				_next_type(current_type),
				wall_min,
				wall_max,
				open_min,
				open_max,
			):
				possible_lengths.append(l)

		if possible_lengths.is_empty():
			printerr("No valid segmentation possible")
			return []

		var chosen := possible_lengths[rng.randi_range(0, possible_lengths.size() - 1)]
		segments.append(Segment.new(current_type, chosen))

		remaining -= chosen
		current_type = _next_type(current_type)

	return segments


func _can_fill_rest(
	remaining: int,
	start_type: Segment.SegmentType,
	wall_min: int,
	wall_max: int,
	open_min: int,
	open_max: int
) -> bool:
	var open_count: int = 0
	var wall_count: int = 0
	var type := start_type
	for i in range(0, remaining + 1):
		if type == Segment.SegmentType.WALL:
			wall_count += 1
		else:
			open_count += 1

		var min_len := wall_count * wall_min + open_count * open_min
		var max_len := wall_count * wall_max + open_count * open_max

		if min_len <= remaining and remaining <= max_len:
			return true

		type = _next_type(type)
	return false


func _generate_obstacle_segments(
	total_length: int,
	open_min: int,
	open_max: int,
	rng: RandomNumberGenerator,
	obstacle_sizes: Array[int] = []
) -> Array[Segment]:
	_obstacle_sizes = obstacle_sizes
	for i in range(open_min, open_max + 1):
		_opening_range.append(i)
	var remaining := total_length
	var current_type := Segment.SegmentType.WALL
	if rng.randf() > 0.5:
		current_type = Segment.SegmentType.OPENING
	return _recursive_build(remaining, current_type)


func _recursive_build(remaining: int, type: Segment.SegmentType) -> Array[Segment]:
	if remaining == 0:
		return []

	var shuffled_obst_sizes = _obstacle_sizes
	var valid_lengths: Array[int]
	if type == Segment.SegmentType.WALL:
		shuffled_obst_sizes.shuffle()
		valid_lengths = shuffled_obst_sizes
	else:
		_opening_range.shuffle()
		valid_lengths = _opening_range

	for length in valid_lengths:
		var rest = remaining - length
		if rest < 0:
			continue

		var sub = _recursive_build(rest, _next_type(type))
		if sub != [null]:
			var seg_array: Array[Segment]
			seg_array.append(Segment.new(type, length))
			seg_array.append_array(sub)
			return seg_array

	return [null]


func _next_type(t: Segment.SegmentType) -> Segment.SegmentType:
	return (
		Segment.SegmentType.OPENING if t == Segment.SegmentType.WALL else Segment.SegmentType.WALL
	)


func print_segments(segments: Array[Segment]) -> void:
	var parts: Array[String] = []

	for seg in segments:
		var type_str := "wall" if seg.type == Segment.SegmentType.WALL else "opening"
		parts.append("(%s, %d)" % [type_str, seg.length])

	print("[" + ", ".join(parts) + "]")
