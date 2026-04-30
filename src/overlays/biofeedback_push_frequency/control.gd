extends Control

var pos_init_slider

@export var min_value = 0.4
@export var max_value = 2.5

@export var min_target_value = 1.0
@export var max_target_value = 2.0

@export var value = 0.4


func _process(_delta) -> void:

	$VBoxContainer/max.text = str(max_value)
	$VBoxContainer/min.text = str(min_value)
	$VBoxContainer/ColorRect/ControlSlider/HBoxContainer/value.text = str(snappedf(value, 0.1))

	$VBoxContainer/ColorRect/ControlSlider.position.y = $VBoxContainer/ColorRect.size.y - (value - min_value) * $VBoxContainer/ColorRect.size.y / (max_value-min_value)
	$VBoxContainer/ColorRect/ControlSlider/HBoxContainer/slider.size.x = $VBoxContainer/ColorRect.size.x
	
	$VBoxContainer/ColorRect/ControlTarget.position.y = $VBoxContainer/ColorRect.size.y - (min_target_value - min_value) * $VBoxContainer/ColorRect.size.y / (max_value-min_value)
	$VBoxContainer/ColorRect/ControlTarget/ColorRect.size.y = $VBoxContainer/ColorRect.size.y * (max_target_value - min_target_value) / (max_value - min_value) + $VBoxContainer/ColorRect.size.y * (max_target_value - max_target_value)

	$VBoxContainer/ColorRect/ControlTarget/ColorRect/min.text = str(min_target_value)	
	$VBoxContainer/ColorRect/ControlTarget/ColorRect/max.text = str(max_target_value)
	
	$VBoxContainer/ColorRect/ControlTarget/ColorRect/max.position.y = $VBoxContainer/ColorRect/ControlTarget/ColorRect.size.y
