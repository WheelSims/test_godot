extends Node3D
class_name Crowd

@export var race_manager : RaceManager
@export var crowd : Array[Node3D]
@onready var audio_stream : AudioStreamPlayer3D = $audio_stream_player
var _player_in: bool = false

func _process(_delta: float) -> void:
	if _player_in:
		# Make humans look at the player
		for human in crowd:
			if Globals.player:
				human.look_at(Globals.player.global_position, Vector3.UP, true)

func _start_clap() -> void:
	_player_in = true
	audio_stream.play()
	for human in crowd:
		var anim_tree = human.get_node("AnimationTree")
		anim_tree.set("parameters/Blend2/blend_amount", 1)

func _stop_clap()->void:
	_player_in = false
	audio_stream.stop()
	for human in crowd:
		var anim_tree = human.get_node("AnimationTree")
		anim_tree.set("parameters/Blend2/blend_amount", 0)

func _on_trigger_area_entered(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_start_clap()

func _on_trigger_area_exited(area: Area3D) -> void:
	if area.is_in_group("Player"):
		_stop_clap()
