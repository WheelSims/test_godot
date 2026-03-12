extends Node3D
class_name ObstacleRaceGame

@export var obstacle_collision: bool = false
@export var on_challenge: bool = false
@export var success_point_val = 10.0
@export var fail_point_val = 5.0
@export var score_popup_scene: PackedScene
@export var score_label: Label
@export var challenge_success_sound: AudioStreamWAV
@export var challenge_fail_sound: AudioStreamWAV
@export var race_success_sound: AudioStreamWAV
@onready var sfx_player: AudioStreamPlayer = $sfx_player
@onready var music_player: AudioStreamPlayer = $music_player
var races_data: Array[RaceData]
var current_race_data: RaceData
var current_race_data_i : int = 0
var total_score = 0
	
func init(_races_data: Array[RaceData])->void:
	randomize()
	races_data = _races_data
	current_race_data = races_data[0]
	add_score(0)
	if is_instance_valid(music_player) and is_instance_valid(music_player.stream) :
		music_player.play()

func add_score(score: int = 0):
	var popup: ScorePopup = score_popup_scene.instantiate()
	popup.global_position = Vector2(randf_range(-100, 100),randf_range(-100, 100))
	add_child(popup)
	popup.show_score(score)
	current_race_data.score += score
	total_score += score
	score_label.text = str(total_score)
	
func play_sfx(audio: AudioStreamWAV)->void:
	sfx_player.stream = audio
	sfx_player.play()
	
func on_obstacle_collision(body: Area3D, area3D_emitter: Area3D)->void:
	if body.is_in_group("Player"):
		current_race_data.score -= fail_point_val
		add_score(-fail_point_val)
		play_sfx(challenge_fail_sound)
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
		add_score(success_point_val)
		play_sfx(challenge_success_sound)
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
	play_sfx(race_success_sound)
	area3D_emitter.set_deferred("monitoring", false)
