extends Node3D
enum RaceType {
	TIME_TRIAL,
	DISTANCE_CHALLENGE,
	NONE
}
@export var race_choice_menu: PanelContainer
var player: RigidBody3D
var current_type: RaceType
var current_race_mode: Race = null
var distance_input: float = 0
var timer_input: float = 0
var player_pos: Vector3
var last_player_pos: Vector3
var traveled_distance: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (current_race_mode):
		_get_distance()
		current_race_mode.update(delta, traveled_distance)
		if (current_race_mode.is_finished()):
			print("race finished!")
			current_race_mode = null
			current_type = RaceType.NONE

func _start_race() -> void:
	traveled_distance = 0
	if (current_type == RaceType.TIME_TRIAL):
		current_race_mode = TimeTrial.new(distance_input)
	elif (current_type == RaceType.DISTANCE_CHALLENGE):
		current_race_mode = DistanceChallenge.new(timer_input)
	else:
		current_race_mode = null
		push_error("Please choose a race type.")
		return
	player_pos = player.global_position
	print("Start!")
	current_race_mode.start()

func _get_distance() -> void:
	last_player_pos = player_pos
	player_pos = player.global_position
	traveled_distance += (player_pos - last_player_pos).length()
	
func _on_trigger_area_entered(area: Area3D) -> void:
	if (area.is_in_group("Player")):
		player = area.get_parent()
		race_choice_menu.show()
		current_type = RaceType.NONE

func _on_cancel_pressed() -> void:
	race_choice_menu.hide()


func _on_start_pressed() -> void:
	_start_race()
	race_choice_menu.hide()


func _on_time_trial_button_pressed() -> void:
	current_type = RaceType.TIME_TRIAL


func _on_distance_challenge_button_pressed() -> void:
	current_type = RaceType.DISTANCE_CHALLENGE


func _on_timer_value_changed(value: float) -> void:
	timer_input = value


func _on_distance_value_changed(value: float) -> void:
	distance_input = value
