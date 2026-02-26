class_name Segment
extends RefCounted

enum SegmentType { WALL, OPENING }

var type: SegmentType
var length: int  # in wall_instance unit or quantum obstacle unit

func _init(t: SegmentType, l: int):
	type = t
	length = l
