extends Resource
class_name RaceData

@export var border_sample: PackedScene
@export var obstacle_sample: PackedScene
@export var race_length: int = 100
@export var race_width: float = 10
@export var object_size_range: Vector2 = Vector2(0.5,3)
## The correct name is not object but challenge: depth_dist_btw_challenge_range
@export var depth_dist_btw_object_range: Vector2 = Vector2(5,20)
@export var horiz_dist_btw_object_range: Vector2 = Vector2(3,5)
@export var opening_size_range: Vector2 = Vector2(3,5)
@export var wall_size_range: Vector2 = Vector2(4, 7)
##This variable may be deleted and used for obstacle generation for now.
@export var min_passage_size = 2
##Probability that next challenge is an opening line or an obstacle line. 1 for opening and 0 for obstacle.
@export var obstacle_opening_prob: float
##Probability that the walls of the opening line of the current challenge are transparent or not (fence or brickwall). 1 for transparency and 0 for opacity.
@export var transparent_op_wall_prob: float
