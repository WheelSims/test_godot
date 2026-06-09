extends Control

@export var numerical_display_label: Label

func _process(_delta):
	var speed: float
	if Globals.player:
		speed = Globals.player.get_linear_speed()
	else:
		speed = 0.0
		
	if abs(speed) < 0.01:
		speed = 0.0

	numerical_display_label.text =  "%0.1f m/s" % speed
	
	# Should we quit
	if not Config.get_value("overlays.speed_indicator.enabled"):
		queue_free()
