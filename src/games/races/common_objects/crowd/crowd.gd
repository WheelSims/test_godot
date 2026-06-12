extends Node3D
class_name Crowd

@export var race_manager: RaceManager
@export var crowd: Array[Node3D]
@onready var audio_stream: AudioStreamPlayer3D = $audio_stream_player
var _player_in: bool = false
var _anim_fade_duration: float = 1.0


func _process(_delta: float) -> void:
	if _player_in:
		# Make humans look at the player
		for human in crowd:
			if Globals.player:
				human.look_at(Globals.player.global_position, Vector3.UP, true)


func _set_animation_blend(amount):
	# Set sound volume
	audio_stream.max_db = (amount - 1) * 6
	if amount == 0:
		audio_stream.stop()

	for human in crowd:
		var anim_tree = human.get_node("AnimationTree")
		anim_tree.set("parameters/Blend2/blend_amount", amount)


func _start_clap() -> void:
	_player_in = true
	audio_stream.play()
	var tween = create_tween()
	tween.tween_method(_set_animation_blend, 0.0, 1.0, _anim_fade_duration)


func _stop_clap() -> void:
	_player_in = false
	var tween = create_tween()
	tween.tween_method(_set_animation_blend, 1.0, 0.0, _anim_fade_duration)


func _on_trigger_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_start_clap()


func _on_trigger_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_stop_clap()
