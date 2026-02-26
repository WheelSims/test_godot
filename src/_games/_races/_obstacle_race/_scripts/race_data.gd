extends Resource
class_name RaceData

@export var border_samples: Array[PackedScene]
@export var obstacle_infos: Array[ObjectInfo]
@export var race_length: int = 100
@export var race_width: float = 10
@export var obst_size_range: Vector2 = Vector2(0.5,3)
@export var depth_dist_btw_challenge_range: Vector2 = Vector2(5,20)
@export var horiz_dist_btw_obst_range: Vector2 = Vector2(3,5)
@export var opening_size_range: Vector2 = Vector2(3,5)
@export var wall_size_range: Vector2 = Vector2(4, 7)
##Probability that next challenge is an opening line or an obstacle line. 0 for opening and 1 for obstacle.
@export var obstacle_opening_prob: float
##Probability that the walls of the opening line of the current challenge are transparent or not (fence or brickwall). 1 for transparency and 0 for opacity.
@export var transparent_op_wall_prob: float
