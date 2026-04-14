extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

var window

func _ready() -> void:
	window_user()

	# Ensure OptiTrack is added when this overlay scene runs standalone (outside main)
	if not main:
		var instance = preload("res://devices/optitrack/optitrack.tscn").instantiate()
		add_child(instance)

#func _process(_delta):
	
	#if main:
		#if not Config.get_value("overlays.biofeedback_optitrack.enabled"):
			#queue_free()


# Create window gui for aiming at wheel centers and hands
func window_user():
	window = Window.new()
	window.title = "Aiming GUI"
	window.size = Vector2i(350, 750)
	window.position = Vector2i(10, 50)
	window.always_on_top = true
	window.unresizable = true
	var scene = load("res://overlays/biofeedback_elbows_angles_gui.tscn").instantiate()
	window.add_child(scene)

	add_child(window)


# Close the window gui when the node exits the scene tree
func _exit_tree():
	window.queue_free()
