extends Node3D
class_name ObstacleRaceGame

@export var obstacle_collision: bool = false
@export var on_challenge: bool = false
@export var success_point_val = 10.0
@export var fail_point_val = 5.0
@export var score_popup_scene: PackedScene
@export var score_label: Label
@export var lap_time_label: Label
@export var total_time_label: Label
@export var challenge_success_sound: AudioStreamWAV
@export var challenge_fail_sound: AudioStreamWAV
@export var race_success_sound: AudioStreamWAV
@onready var sfx_player: AudioStreamPlayer = $sfx_player
@onready var music_player: AudioStreamPlayer = $music_player
var races_data: Array[RaceData]
var current_race_data: RaceData
var current_race_data_i : int = -1 ## -1 means race didn't started
var total_score = 0
var total_timer = 0.0
var lap_timer = 0.0
var race_on_pause = true

func init(_races_data: Array[RaceData])->void:
	randomize()
	races_data = _races_data
	current_race_data = races_data[0]
	score_label.text = str(0)
	if is_instance_valid(music_player) and is_instance_valid(music_player.stream) :
		music_player.play()
		
func _process(delta: float) -> void:
	if not race_on_pause:
		total_timer += delta
		lap_timer += delta
		_update_labels()
	
func _update_labels()->void:
	lap_time_label.text = "%.1f" % lap_timer
	total_time_label.text = "%.1f" % total_timer

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
		add_score(-fail_point_val)
		play_sfx(challenge_fail_sound)
		obstacle_collision = true
		area3D_emitter.set_deferred("monitoring", false)
	
func on_challenge_area_entered(body: Area3D, _area3D_emitter: Area3D)->void:
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
	
func on_race_entered(body: Area3D, area3D_emitter: Area3D)->void:
	if not body.is_in_group("Player"):
		return
	race_on_pause = false
	lap_timer = 0
	
	if current_race_data_i < races_data.size()-1:
		current_race_data_i += 1
		current_race_data = races_data[current_race_data_i]
		current_race_data.score = 0
		set_crowds_visible(current_race_data.final_crowds, true)
	if current_race_data_i < races_data.size()-1:
		set_crowds_visible(races_data[current_race_data_i+1].start_crowds, true)
	area3D_emitter.set_deferred("monitoring", false)
	
func on_race_exited(body: Area3D, area3D_emitter: Area3D)->void:
	if not body.get_parent().is_in_group("Player"):
		return
	current_race_data.lap_time = lap_timer
	race_on_pause = true
	play_sfx(race_success_sound)
	set_crowds_visible(races_data[current_race_data_i].start_crowds, false)
	if current_race_data_i > 0:
		set_crowds_visible(races_data[current_race_data_i-1].final_crowds, false)
	area3D_emitter.set_deferred("monitoring", false)
	
func set_crowds_visible(crowds: Array[Crowd], _visible:bool)->void:
	if crowds.size() == 0:
		return
	for crowd in crowds:
		crowd.visible = _visible
