class_name SegmentGenerator
extends RefCounted

func generate_segments(
		total_length: int,
		wall_min: int,
		wall_max: int,
		open_min: int,
		open_max: int,
		rng: RandomNumberGenerator
		) -> Array[Segment]:

	var segments: Array[Segment] = []
	var remaining := total_length
	var current_type := Segment.SegmentType.WALL
	if (rng.randf()>0.5):
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
				push_error("No valid segmentation possible")
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
				open_max
			):
				possible_lengths.append(l)

		if possible_lengths.is_empty():
			push_error("No valid segmentation possible")
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

	# We test every possible numbers of the remaining segments

	for wall_count in range(0, remaining + 1):
		var open_count := wall_count

		if start_type == Segment.SegmentType.OPENING:
			open_count += 1
		else:
			wall_count += 1
			

		var min_len := wall_count * wall_min + open_count * open_min

		var max_len := wall_count * wall_max + open_count * open_max

		if min_len <= remaining and remaining <= max_len:
			return true

	return false
	
func _next_type(t: Segment.SegmentType) -> Segment.SegmentType:
	return Segment.SegmentType.OPENING if t == Segment.SegmentType.WALL else Segment.SegmentType.WALL
	
static func units_to_world(units: int, quantum: float) -> float:
	return units * quantum
	
func print_segments(segments: Array[Segment]) -> void:
	var parts: Array[String] = []

	for seg in segments:
		var type_str := "wall" if seg.type == Segment.SegmentType.WALL else "opening"
		parts.append("(%s, %d)" % [type_str, seg.length])

	print("[" + ", ".join(parts) + "]")
