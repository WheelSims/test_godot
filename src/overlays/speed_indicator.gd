extends Control

@onready var main: Node = get_tree().get_root().get_node("main")
@export var numerical_display_label: Label

func _process(delta):
	var speed: float
	if main.player:
		speed = main.player.get_linear_speed()
	else:
		speed = 0.0
		
	if abs(speed) < 0.01:
		speed = 0.0

	numerical_display_label.text =  "%0.1f m/s" % speed
	
	# Should we quit
	if not main.config.get_value("overlays.speed_indicator.enabled"):
		queue_free()
