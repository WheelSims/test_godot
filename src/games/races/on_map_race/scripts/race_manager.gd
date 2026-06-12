class_name RaceManager
extends Node3D

enum RaceType { TIME_TRIAL, DISTANCE_CHALLENGE, NONE }

#Game Elements
@export_group("Game Elements")
@export var path: Path3D
@export var distance_between_arrows: float = 5.0
@export var end_arch_right_crowd = false
@export var end_arch_left_crowd = false

# Scenes
@export var arrow_scene: PackedScene
@export var final_arch_scene: PackedScene

#Music & SFX
@export var click_tone: AudioStream
@export var click_error: AudioStream
@export var victory_sound: AudioStream

@export var music_intro: AudioStream
@export var music_loop: AudioStream

# Runtime Variables
var distance_input: float = 0
var timer_input: float = 0
var _instantiated_arrows: Array[Node3D] = []
var _final_arch: Node3D = null
var _on_race: bool = false
var _current_race_type: RaceType = RaceType.NONE
var _current_race_mode: Race = null
var _total_race_length: float = 0

# UI Elements
@onready var race_hud: MarginContainer = %RaceHUD
@onready var timer_label: Label = %Timer
@onready var distance_label: Label = %Distance
@onready var countdown_ui: Control = %Countdown
@onready var sfx_player: AudioStreamPlayer = $UI/SFXPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer


func _ready() -> void:
	if Config.get_value("game.racing.type") == 0:
		_current_race_type = RaceType.TIME_TRIAL
	elif Config.get_value("game.racing.type") == 1:
		_current_race_type = RaceType.DISTANCE_CHALLENGE
	else:
		_current_race_type = RaceType.NONE

	distance_input = Config.get_value("game.racing.distance")
	timer_input = Config.get_value("game.racing.time")

	if path:
		_total_race_length = path.curve.get_baked_length()

	_place_final_arch(distance_input)


func _process(delta: float) -> void:
	if _current_race_mode and _on_race:
		_current_race_mode.update(delta)
		_update_hud(_current_race_mode.current_distance, _current_race_mode.timer)

		if _current_race_mode.is_finished():
			_finish_race()


func _start_race() -> void:
	var race_length = _total_race_length

	match _current_race_type:
		RaceType.TIME_TRIAL:
			_current_race_mode = TimeTrial.new(distance_input, Globals.player)
			_place_final_arch(distance_input)
			race_length = distance_input
		RaceType.DISTANCE_CHALLENGE:
			_current_race_mode = DistanceChallenge.new(timer_input, Globals.player)
			if _final_arch != null:
				_final_arch.queue_free()
		_:
			return

	sfx_player.play()
	countdown_ui.start_countdown()

	# Wait for signal before starting race
	await countdown_ui.countdown_finished

	_on_race = true
	_play_music()
	race_hud.show()
	_spawn_arrows(distance_between_arrows, race_length)


func _finish_race() -> void:
	music_player.stream = victory_sound
	music_player.play()
	_current_race_mode = null
	_on_race = false
	_current_race_type = RaceType.NONE
	_clear_arrows()


func _place_final_arch(distance: float) -> void:
	distance = fmod(distance, _total_race_length)
	var arch_transform = path.curve.sample_baked_with_rotation(distance)

	if _final_arch == null:
		_final_arch = final_arch_scene.instantiate()
		path.add_child(_final_arch)
		if end_arch_left_crowd:
			var left_crowd = _final_arch.get_node("LeftCrowd")
			left_crowd.visible = true
			left_crowd.race_manager = self
		if end_arch_right_crowd:
			var right_crowd = _final_arch.get_node("RightCrowd")
			right_crowd.visible = true
			right_crowd.race_manager = self

	_final_arch.transform = arch_transform


func _spawn_arrows(spacing: float, length: float) -> void:
	var offset: float = 0.0

	while offset < length:
		var arrow: Node3D = arrow_scene.instantiate()
		var arrow_transform = path.curve.sample_baked_with_rotation(offset)
		path.add_child(arrow)
		arrow.transform = arrow_transform
		arrow.rotation.y += PI / 2
		arrow.global_position += Vector3.UP * 0.1
		_instantiated_arrows.append(arrow)
		offset += spacing


func _clear_arrows() -> void:
	for arrow in _instantiated_arrows:
		arrow.queue_free()
	_instantiated_arrows.clear()


func _update_hud(distance: float, timer: float) -> void:
	match _current_race_type:
		RaceType.TIME_TRIAL:
			timer_label.text = "Time: %.1f s" % timer
			distance_label.text = "Distance Left: %.1f m" % abs(distance_input - distance)
		RaceType.DISTANCE_CHALLENGE:
			timer_label.text = "Time Left: %.1f s" % abs(timer_input - timer)
			distance_label.text = "Distance: %.1f m" % distance


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
