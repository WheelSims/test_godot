extends Node3D
class_name RaceManager

enum RaceType { TIME_TRIAL, DISTANCE_CHALLENGE, NONE }

#UI Elements
@export_group("UI Elements")
@export var raceHUD: MarginContainer
@export var timerLabel: Label
@export var distanceLabel: Label
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
@export var click_tone: AudioStream
@export var click_error: AudioStream
@export var victory_sound: AudioStream

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@export var music_intro: AudioStream
@export var music_loop: AudioStream

# Runtime Variables
var _instantiatedArrows: Array[Node3D] = []
var _finalArch: Node3D = null
var _racePaused: bool = false
var _on_race: bool = false
var _currentRaceType: RaceType = RaceType.NONE
var _currentRaceMode: Race = null
var distanceInput: float = 0
var timerInput: float = 0
var _totalRaceLength: float = 0


func _ready() -> void:
	if Config.get_value("game.racing.type") == 0:
		_currentRaceType = RaceType.TIME_TRIAL
	elif Config.get_value("game.racing.type") == 1:
		_currentRaceType = RaceType.DISTANCE_CHALLENGE
	else:
		_currentRaceType = RaceType.NONE

	distanceInput = Config.get_value("game.racing.distance")
	timerInput = Config.get_value("game.racing.time")

	if path:
		_totalRaceLength = path.curve.get_baked_length()

	_place_final_arch(distanceInput)


func _process(delta: float) -> void:
	if _currentRaceMode and _on_race:
		if not _racePaused:
			_currentRaceMode.update(delta)
			_update_hud(_currentRaceMode.current_distance, _currentRaceMode.timer)

		if _currentRaceMode.is_finished():
			_finish_race()


func _start_race() -> void:
	var raceLength = _totalRaceLength

	match _currentRaceType:
		RaceType.TIME_TRIAL:
			_currentRaceMode = TimeTrial.new(distanceInput, Globals.player)
			_place_final_arch(distanceInput)
			raceLength = distanceInput
		RaceType.DISTANCE_CHALLENGE:
			_currentRaceMode = DistanceChallenge.new(timerInput, Globals.player)
			if _finalArch != null:
				_finalArch.queue_free()
		_:
			return

	SFX_player.play()
	countdown_ui.start_countdown()

	# Wait for signal before starting race
	await countdown_ui.countdown_finished

	_on_race = true
	_play_music()
	raceHUD.show()
	_racePaused = false
	_spawn_arrows(distanceBetweenArrows, raceLength)


func _finish_race() -> void:
	music_player.stream = victory_sound
	music_player.play()
	_currentRaceMode = null
	_on_race = false
	_currentRaceType = RaceType.NONE
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
		var arrow_transform = path.curve.sample_baked_with_rotation(offset)
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
			distanceLabel.text = "Distance Left: %.1f m" % abs(distanceInput - distance)
		RaceType.DISTANCE_CHALLENGE:
			timerLabel.text = "Time Left: %.1f s" % abs(timerInput - timer)
			distanceLabel.text = "Distance: %.1f m" % distance


func _play_music() -> void:
	music_player.stream = music_intro
	music_player.play()

	await music_player.finished

	if _on_race:
		music_player.stream = music_loop
		music_player.play()


func _on_trigger_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_start_race()
