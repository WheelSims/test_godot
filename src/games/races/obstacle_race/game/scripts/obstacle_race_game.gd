extends Node3D
class_name ObstacleRaceGame

@export var obstacle_collision: bool = false
@export var on_challenge: bool = false
@export var success_point_val = 10.0
@export var fail_point_val = 5.0
var races_data: Array[RaceData]
var current_race_data: RaceData
var current_race_data_i : int = 0
var total_score = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func assign_races_datas(_races_data: Array[RaceData])->void:
	races_data = _races_data
	current_race_data = races_data[0]

func on_obstacle_collision(body: Node3D)->void:
	if on_challenge and body is Player:
		current_race_data.score -= fail_point_val
		print(current_race_data.score)
		obstacle_collision = true
	
func on_challenge_body_entered(body: Node3D)->void:
	if body is Player:
		on_challenge = true

func on_challenge_body_exited(body: Node3D, area3D_emitter: Area3D)->void:
	if body is not Player:
		return
	on_challenge = false
	if not obstacle_collision:
		current_race_data.score += success_point_val
		print(current_race_data.score)
	obstacle_collision = false
	area3D_emitter.set_deferred("monitoring", false)
	
func on_race_entered(body: Node3D)->void:
	if body is not Player:
		return
	print("ya")
	if current_race_data_i < races_data.size()-1:
		current_race_data_i += 1
		current_race_data = races_data[current_race_data_i]
		
func on_race_exited(body: Node3D, area3D_emitter: Area3D)->void:
	if body is not Player:
		return
	total_score += current_race_data.score
	print(total_score)
	area3D_emitter.set_deferred("monitoring", false)
