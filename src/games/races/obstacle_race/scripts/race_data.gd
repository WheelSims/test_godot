extends Resource
class_name RaceData
## Class that takes all the parameters of an obstacle race.

@export var race_length: int = 100
@export var race_width: float = 10
## The min and max of distance between the challenges. 
@export var challenge_gap_range: Vector2 = Vector2(5,10)
## The value randomly choosen and that is the same on one race.
var challenge_gap: float
## The min and max of obstacle sizes.
@export var obst_size_range: Vector2 = Vector2(0.5,3)
## The min and max of distance between the obstacles.
@export var obst_gap_range: Vector2 = Vector2(3,5)
## The min and max of distance between walls.
@export var opening_size_range: Vector2 = Vector2(3,5)
## The min and max of wall sizes.
@export var wall_size_range: Vector2 = Vector2(4, 7)
##Probability that next challenge is an opening line or an obstacle line. 0 for opening and 1 for obstacle.
@export var obstacle_opening_prob: float
##Probability that the walls of the opening line of the current challenge are transparent or not (fence or brickwall). 1 for transparency and 0 for opacity.
@export var transparent_op_wall_prob: float
# _race_start_x and _end_race_x_pos reset at every new level
var race_start_x : float = 0
var end_race_x_pos : float = 0
