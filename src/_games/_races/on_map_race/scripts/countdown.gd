extends Control

signal countdown_finished

@onready var label: Label = $NumberLabel
@onready var audio_stream: AudioStreamPlayer = $Bips
@export var low_bip: AudioStream
@export var high_bip: AudioStream
var tween: Tween

var countdown_values := ["3", "2", "1", "GO!"]

func start_countdown():
	audio_stream.stream = low_bip
	visible = true
	_process_countdown(0)

func _process_countdown(index: int) -> void:
	label.text = countdown_values[index]
	label.modulate = Color(1, 1, 1, 1)
	label.scale = Vector2.ONE * 0.5
	
	tween = get_child(0).create_tween()
	if index <= 2:
		audio_stream.play()
	elif index == 3:
		audio_stream.stream = high_bip
		audio_stream.play()
	tween.tween_property(label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.2).set_delay(0.2)
	
	if index >= countdown_values.size()-1:
		emit_signal("countdown_finished")

	await tween.finished
	await get_tree().create_timer(0.2).timeout
	
	if index >= countdown_values.size()-1:
		visible = false
		return
	
	_process_countdown(index + 1)
