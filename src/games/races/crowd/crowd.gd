extends Node3D

class_name Crowd

@export var race_manager : RaceManager
@export var crowd : Array[Node3D]
@export var audio_stream : AudioStreamPlayer3D
@export var _start_applaud : AudioStream
@export var _applaud_loop : AudioStream
var _player_in: bool = false
var _trans_anim: float = 0
@export var trans_accel: float = 2
@export var is_final_crowd_on_race = false
var on_race: bool = true
var _player_area: Area3D
@export var max_applaud_distance : float

func _ready() -> void:		
	audio_stream.stream = _start_applaud
	
func _process(delta: float) -> void:
	if race_manager:
		on_race = race_manager._on_race
	
	# Too far -> Stop applauding
	if (audio_stream.playing and _player_area and _player_area.global_position.distance_to(global_position) > max_applaud_distance):
		_stop_clap()
	
	# Applaud Conditions
	if (_trans_anim < 1 and _player_in and on_race):
		_trans_anim = lerp(_trans_anim ,1.1, trans_accel * delta)
		_clap(_trans_anim)
		if not audio_stream.playing:
			_play_sound()
	elif (_trans_anim>0 and !on_race and !is_final_crowd_on_race):
		_trans_anim = 0
		_clap(_trans_anim)
		audio_stream.stop()
	if not audio_stream.playing and _trans_anim > 0:
		_trans_anim = 0
		_clap(_trans_anim)
	
	##For humans to look at the player
	if (_trans_anim>0):
		for human in crowd:
			human.look_at(_player_area.global_position, Vector3.UP, true)

func _play_sound() -> void:
	audio_stream.play()
	
	await audio_stream.finished
	
	if (on_race):
		audio_stream.stream = _applaud_loop
		audio_stream.play()
	
	
func _clap(__trans_anim: float) -> void:
	for human in crowd:
			var anim_tree = human.get_node("AnimationTree")
			anim_tree.set("parameters/Blend2/blend_amount", __trans_anim)
			
func _stop_clap()->void:
	_player_in = false
	_clap(0)
	audio_stream.stop()

func _on_trigger_area_entered(area: Area3D) -> void:
	if (area.is_in_group("Player")):
		_player_area = area
		_player_in = true
