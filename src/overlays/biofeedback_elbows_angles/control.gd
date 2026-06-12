extends Control

var pos_init_slider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VBoxContainer/max.text = str(180)
	$VBoxContainer/min.text = str(0)
	pos_init_slider = $VBoxContainer/ColorRect/HBoxContainer.position


func _process(_delta: float) -> void:
	var flexion = $"../elbow_right".alpha
	$VBoxContainer/ColorRect/HBoxContainer/value.text = str(snappedi(flexion, 1))
	$VBoxContainer/ColorRect/HBoxContainer.position = (
		pos_init_slider - Vector2(0, flexion * 100 / 180)
	)
