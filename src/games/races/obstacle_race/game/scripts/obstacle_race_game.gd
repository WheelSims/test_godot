extends Node3D
class_name ObstacleRaceGame

@export var obstacle_collision: bool = false
@export var on_challenge: bool = false
@export var success_point_val = 10.0
@export var fail_point_val = 5.0
@export var score_popup_scene: PackedScene
var races_data: Array[RaceData]
var current_race_data: RaceData
var current_race_data_i : int = 0
var total_score = 0
	
func _ready()->void:
	randomize()
func assign_races_datas(_races_data: Array[RaceData])->void:
	races_data = _races_data
	current_race_data = races_data[0]

func add_score(score: int = 0):
	var popup: ScorePopup = score_popup_scene.instantiate()
	popup.global_position = Vector2(randf_range(-100, 100),randf_range(-100, 100))
	add_child(popup)
	popup.show_score(score)
	
func on_obstacle_collision(body: Area3D, area3D_emitter: Area3D)->void:
	if body.is_in_group("Player"):
		current_race_data.score -= fail_point_val
		add_score(-5)
		obstacle_collision = true
		area3D_emitter.set_deferred("monitoring", false)
	
func on_challenge_area_entered(body: Area3D)->void:
	if body.is_in_group("Player"):
		on_challenge = true
		obstacle_collision = false

func on_challenge_area_exited(body: Area3D, area3D_emitter: Area3D)->void:
	if not body.is_in_group("Player"):
		return
	on_challenge = false
	if not obstacle_collision:
		current_race_data.score += success_point_val
		add_score(10)
	area3D_emitter.set_deferred("monitoring", false)
	
func on_race_entered(body: Area3D)->void:
	if not body.is_in_group("Player"):
		return
	if current_race_data_i < races_data.size()-1:
		current_race_data_i += 1
		current_race_data = races_data[current_race_data_i]
		
func on_race_exited(body: Area3D, area3D_emitter: Area3D)->void:
	if not body.get_parent().is_in_group("Player"):
		return
	total_score += current_race_data.score
	area3D_emitter.set_deferred("monitoring", false)
