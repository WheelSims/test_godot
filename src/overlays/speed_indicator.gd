extends Control

@onready var main: Node = get_tree().get_root().get_node("main")
@export var numerical_display_label: Label

func _process(delta):
	if main.player:
		numerical_display_label.text = str(main.player.get_linear_speed()) + " m/s"
	else:
		numerical_display_label.text = "0.0 m/s"
	
	# Should we quit
	if not main.config.get_value("overlays.speed_indicator.enabled"):
		queue_free()
