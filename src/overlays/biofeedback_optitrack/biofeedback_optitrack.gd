extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

# Wheelchair variables
@export_group("Wheels")
@export_subgroup("Wheel Left")
var position_wheel_l
var radius_wheel
@export var visibled_wheel_l = true
@export var visibled_handrim_l = false
@export var visibled_angle_contact_l = true
@export_subgroup("Wheel Right")
var position_wheel_r
@export var visibled_wheel_r = true
@export var visibled_handrim_r = false
@export var visibled_angle_contact_r = true
@export_subgroup("Trails")
@export var trails_visibled = true

# Distances between left and right wheel centers
var anteroposterior_length
var vertical_distance_wheel
var mediolateral_distance_wheel

var window

func _ready() -> void:
	window_user()

	# Ensure OptiTrack is added when this overlay scene runs standalone (outside main)
	if not main:
		var instance = preload("res://devices/optitrack/optitrack.tscn").instantiate()
		add_child(instance)

func _process(_delta):
	var debut = Time.get_ticks_usec()
	update_wheelchair()
	
	if not Config.get_value("overlays.biofeedback_optitrack.enabled"):
		queue_free()
	var fin = Time.get_ticks_usec()
	var temp_execution = (fin - debut)/1_000_000.0
	print("Temps d'exécution biofeedback_optitrack.gd : %.6f secondes" % temp_execution)

# Update wheelchair model based on configuration and tracking data
func update_wheelchair():
	
	# Set wheel radius from configuration
	radius_wheel = Config.get_value("player.pushrim_diameter")
	
	# Compute distances between left and right wheel centers
	anteroposterior_length = abs(Config.get_value("coordinates.left_wheel_center")[0] - Config.get_value("coordinates.right_wheel_center")[0])
	vertical_distance_wheel = abs(Config.get_value("coordinates.left_wheel_center")[1] - Config.get_value("coordinates.right_wheel_center")[1])
	mediolateral_distance_wheel = abs(Config.get_value("coordinates.left_wheel_center")[2] - Config.get_value("coordinates.right_wheel_center")[2])
	
	# Update left wheel scale, position and visibility
	$wheel_left.scale = Vector3(-1/radius_wheel*0.2+1, radius_wheel, radius_wheel)
	position_wheel_l = Vector3(anteroposterior_length/2, vertical_distance_wheel/2, -mediolateral_distance_wheel/2)
	$wheel_left.position = position_wheel_l
	$wheel_left.visible = visibled_wheel_l
	
	# Update left wheel sub-elements visibility
	$wheel_left/angle_start_contact_left.visible = visibled_angle_contact_l
	$wheel_left/angle_end_contact_left.visible = visibled_angle_contact_l
	$wheel_left/handrim_left.visible = visibled_handrim_l

	# Update right wheel scale, position and visibility
	$wheel_right.scale = Vector3(-1/radius_wheel*0.2+1, radius_wheel, radius_wheel)
	position_wheel_r = Vector3(anteroposterior_length/2, vertical_distance_wheel/2, mediolateral_distance_wheel/2)
	$wheel_right.position = position_wheel_r
	$wheel_right.visible = visibled_wheel_r
	
	# Update right wheel sub-elements visibility
	$wheel_right/angle_start_contact_right.visible = visibled_angle_contact_r
	$wheel_right/angle_end_contact_right.visible = visibled_angle_contact_r
	$wheel_right/handrim_right.visible = visibled_handrim_r


# Create window gui for aiming at wheel centers and hands
func window_user():
	window = Window.new()
	window.title = "Aiming GUI"
	window.size = Vector2i(350, 650)
	window.position = Vector2i(10, 50)
	window.always_on_top = true
	window.unresizable = true
	var scene = load("res://overlays/biofeedback_optitrack_gui.tscn").instantiate()
	window.add_child(scene)

	add_child(window)


# Close the window gui when the node exits the scene tree
func _exit_tree():
	window.queue_free()
