extends Node3D
class_name Crowd

@onready var audio_stream : AudioStreamPlayer3D = $audio_stream_player
var _player_in: bool = false
var _anim_fade_duration: float = 1.0

func _set_animation_blend(amount):
	# Set sound volume
	audio_stream.max_db = (amount - 1) * 6
	if amount == 0:
		audio_stream.stop()

func _start_clap() -> void:
	_player_in = true
	audio_stream.play()
	var tween = create_tween()
	tween.tween_method(_set_animation_blend, 0.0,  1.0, _anim_fade_duration)

func _stop_clap()->void:
	_player_in = false
	var tween = create_tween()
	tween.tween_method(_set_animation_blend, 1.0,  0.0, _anim_fade_duration)

func _on_trigger_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_start_clap()

func _on_trigger_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_stop_clap()
