extends Control

@onready var main: Node = get_tree().get_root().get_node("main")

@onready var numerical_display_label: Label = get_node("numerical_display/text")

func _process(delta):
	if main.player:
		numerical_display_label.text = str(main.player.get_linear_speed()) + " m/s"
	else:
		numerical_display_label.text = ""
