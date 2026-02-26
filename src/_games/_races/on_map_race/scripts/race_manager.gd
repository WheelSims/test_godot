extends Node3D
class_name RaceManager

enum RaceType { TIME_TRIAL, DISTANCE_CHALLENGE, NONE }

#UI Elements
@export_group("UI Elements")
@export var raceChoiceMenu: PanelContainer
@export var raceLengthLabel: Label
@export var distance_challenge_button: Button
@export var time_trial_button: Button
@export var raceHUD: MarginContainer
@export var timerLabel: Label
@export var distanceLabel: Label
@export var endMenu: PanelContainer
@export var endScoreLabel: Label
@export var endParameterLabel: Label
@export var pauseMenu: PanelContainer
@export var race_mode_pause_menu: Label
@export var race_mode_end_menu: Label
@export var race_parameter: Label
@export var countdown_ui: Control


#Game Elements
@export_group("Game Elements")
@export var path: Path3D
@export var distanceBetweenArrows: float = 5.0
@export var end_arch_right_crowd = false
@export var end_arch_left_crowd = false

# Scenes
@export var arrowScene: PackedScene
@export var finalArchScene: PackedScene

#Music & SFX
@onready var SFX_player: AudioStreamPlayer = $UI/SFXPlayer
@export var click_tone : AudioStream
@export var click_error : AudioStream
@export var victory_sound : AudioStream

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@export var music_intro : AudioStream
@export var music_loop : AudioStream

# Runtime Variables
var _instantiatedArrows: Array[Node3D] = []
var _finalArch: Node3D = null
var _racePaused: bool = false
var _on_race: bool = false
var _player: RigidBody3D
var _currentRaceType: RaceType = RaceType.NONE
var _currentRaceMode: Race = null
var distanceInput: float = 0
var timerInput: float = 0
var _totalRaceLength: float = 0

func _ready() -> void:
	if (path):
		_totalRaceLength = path.curve.get_baked_length()
		raceLengthLabel.text = "Total Race Length = %.0f m" % _totalRaceLength

func _process(delta: float) -> void:
	if _currentRaceMode and _on_race:
		if not _racePaused:
			_currentRaceMode.update(delta)
			_update_hud(_currentRaceMode.current_distance, _currentRaceMode.timer)

		if _currentRaceMode.is_finished():
			_finish_race(false)

func pause_command() -> void:
	if _currentRaceMode:
		_racePaused = !_racePaused
		pauseMenu.visible = _racePaused

func _start_race() -> void:
	var raceLength = _totalRaceLength

	match _currentRaceType:
		RaceType.TIME_TRIAL:
			_currentRaceMode = TimeTrial.new(distanceInput, _player)
			_place_final_arch(distanceInput)
			raceLength = distanceInput
			race_mode_pause_menu.text = "RaceMode: Time Trial"
			race_parameter.text = "Distance to travel = %.1f meters" % distanceInput
		RaceType.DISTANCE_CHALLENGE:
			_currentRaceMode = DistanceChallenge.new(timerInput, _player)
			race_mode_pause_menu.text = "RaceMode: Distance Challenge"
			race_parameter.text = "Timer = %.1f secondes" % timerInput
			if (_finalArch != null):
				_finalArch.queue_free()
		_:
			SFX_player.stream = click_error
			SFX_player.play()
			await SFX_player.finished
			SFX_player.stream = click_tone
			push_error("Please choose a race type.")
			return
	
	
	SFX_player.play()
	raceChoiceMenu.hide()
	countdown_ui.start_countdown()
	
	# Wait for signal before starting race
	await countdown_ui.countdown_finished
	
	_on_race = true
	_play_music()
	raceHUD.show()
	_racePaused = false
	_spawn_arrows(distanceBetweenArrows, raceLength)
	

func _finish_race(forced: bool) -> void:
	if not forced:
		endMenu.show()
		match _currentRaceType:
			RaceType.TIME_TRIAL:
				endScoreLabel.text = "Score: Time = %.1f s" % _currentRaceMode.timer
				endParameterLabel.text = "Parameter: Distance = %.1f m" % _currentRaceMode.current_distance
				race_mode_pause_menu.text = "Time Trial"
			RaceType.DISTANCE_CHALLENGE:
				endScoreLabel.text = "Score: Distance = %.1f m" % _currentRaceMode.current_distance
				endParameterLabel.text = "Parameter: Timer = %.1f s" % _currentRaceMode.timer
				race_mode_pause_menu.text = "Distance Challenge"
				
		
		music_player.stream = victory_sound
		music_player.play()
	else:
		music_player.stop()

	_currentRaceMode = null
	_on_race = false
	raceHUD.hide()
	_currentRaceType = RaceType.NONE
	distance_challenge_button.button_pressed = false
	time_trial_button.button_pressed = false
	
	_clear_arrows()

func _place_final_arch(distance: float) -> void:
	distance = fmod(distance, _totalRaceLength)
	var archTransform = path.curve.sample_baked_with_rotation(distance)

	if _finalArch == null:
		_finalArch = finalArchScene.instantiate()
		path.add_child(_finalArch)
		if end_arch_left_crowd:
			var left_crowd = _finalArch.get_node("LeftCrowd")
			left_crowd.visible = true
			left_crowd.race_manager = self
		if end_arch_right_crowd:
			var right_crowd = _finalArch.get_node("RightCrowd")
			right_crowd.visible = true
			right_crowd.race_manager = self	

	_finalArch.transform = archTransform

func _spawn_arrows(spacing: float, length: float) -> void:
	var offset: float = 0.0

	while offset < length:
		var arrow: Node3D = arrowScene.instantiate()
		var arrow_transform  = path.curve.sample_baked_with_rotation(offset)
		path.add_child(arrow)
		arrow.transform = arrow_transform
		arrow.rotation.y += PI / 2
		arrow.global_position += Vector3.UP * 0.1
		_instantiatedArrows.append(arrow)
		offset += spacing

func _clear_arrows() -> void:
	for arrow in _instantiatedArrows:
		arrow.queue_free()
	_instantiatedArrows.clear()
	
func _update_hud(distance: float, timer: float) -> void:
	match _currentRaceType:
		RaceType.TIME_TRIAL:
			timerLabel.text = "Time: %.1f s" % timer
			distanceLabel.text = "Distance Left: %.1f m" % (distanceInput - distance)
		RaceType.DISTANCE_CHALLENGE:
			timerLabel.text = "Time Left: %.1f s" % (timerInput - timer)
			distanceLabel.text = "Distance: %.1f m" % distance

func _play_music() -> void:
	music_player.stream = music_intro
	music_player.play()
	
	await music_player.finished
	
	if (_on_race):
		music_player.stream = music_loop
		music_player.play()

# Trigger + Input Handling

func _on_trigger_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player") and not _currentRaceMode:
		_player = area.get_parent()
		raceChoiceMenu.show()
		_show_on_front_window(_player)
		_player.race_manager = self
		_currentRaceType = RaceType.NONE
		
func _show_on_front_window(_player: Node3D) -> void:
	var _front_proj = _player.get_node_or_null("FrontProjector")
	var _ui_game = raceChoiceMenu.get_parent()
	if _front_proj:
		_ui_game.get_parent().remove_child(_ui_game)
		_front_proj.add_child(_ui_game)
		

func _on_cancel_pressed() -> void:
	raceChoiceMenu.hide()
	SFX_player.play()

#SFX_player is played in _start_race function for that button
func _on_start_pressed() -> void:
	_start_race()

func _on_time_trial_button_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		_currentRaceType = RaceType.TIME_TRIAL
		distance_challenge_button.button_pressed = false
	else: _currentRaceType = RaceType.NONE
	
	SFX_player.play()

func _on_distance_challenge_button_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		_currentRaceType = RaceType.DISTANCE_CHALLENGE
		time_trial_button.button_pressed = false
	else: _currentRaceType = RaceType.NONE
	
	SFX_player.play()

func _on_timer_value_changed(value: float) -> void:
	timerInput = value
	if not distance_challenge_button.button_pressed:
		distance_challenge_button.button_pressed = true
		SFX_player.play()
		
func _on_distance_value_changed(value: float) -> void:
	distanceInput = value
	if not time_trial_button.button_pressed:
		time_trial_button.button_pressed = true
		SFX_player.play()

# End Menu Callbacks

func _on_cancel_end_menu_pressed() -> void:
	endMenu.hide()
	SFX_player.play()

func _on_restart_end_menu_pressed() -> void:
	_player.global_transform = global_transform
	_player.rotate(-Vector3.DOWN, PI/2)
	endMenu.hide()
	raceChoiceMenu.show()
	SFX_player.play()

# Pause Menu Callbacks

func _on_cancel_pause_pressed() -> void:
	_finish_race(true)
	pauseMenu.hide()
	SFX_player.play()

func _on_restart_pause_pressed() -> void:
	_finish_race(true)
	pauseMenu.hide()
	_player.global_transform = global_transform
	_player.rotate(-Vector3.DOWN, PI/2)
	raceChoiceMenu.show()
	SFX_player.play()

func _on_continue__pause_menu_pressed() -> void:
	pauseMenu.hide()
	_racePaused = false
	SFX_player.play()
