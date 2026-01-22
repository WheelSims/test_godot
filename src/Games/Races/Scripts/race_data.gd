extends Resource
class_name RaceData

@export var border_sample: PackedScene
@export var obstacle_sample: PackedScene
@export var race_length: int = 100
@export var race_width: float = 10
@export var object_size_range: Vector2 = Vector2(0.5,3)
@export var depth_dist_btw_object_range: Vector2 = Vector2(5,20)
@export var horiz_dist_btw_object_range: Vector2 = Vector2(3,5)
@export var min_passage_size = 2
