extends Node3D

@onready var main: Node = get_tree().get_root().get_node("main")

# Wheelchair variables
@export_group("Wheels")

@export_subgroup("Wheel Left")
@export var position_wheel_l = Vector3(0, 0, -0.3)
@export var radius_wheel_l = 0.54
@export var visibled_wheel_l = true
@export var visibled_handrim_l = false
@export var visibled_angle_contact_l = true

@export_subgroup("Wheel Right")
@export var position_wheel_r = Vector3(0, 0, 0.3)
@export var radius_wheel_r = 0.54
@export var visibled_wheel_r = true
@export var visibled_handrim_r = false
@export var visibled_angle_contact_r = true

@export_subgroup("Trails")
@export var trails_visibled = true

var window

func _ready() -> void:
	window_user()

func _process(_delta):
	
	update_wheelchair()
	
	if main:
		if not main.config.get_value("overlays.biofeedback_optitrack.enabled"):
			queue_free()


func update_wheelchair():
	
	$wheel_left.scale = Vector3(-1/radius_wheel_l*0.2+1, radius_wheel_l, radius_wheel_l)
	$wheel_left.position = position_wheel_l
	#$wheel_left.rotation = orientation_wheel_l
	$wheel_left.visible = visibled_wheel_l
	
	$wheel_left/angle_contact_left.visible = visibled_angle_contact_l
	$wheel_left/handrim_left.visible = visibled_handrim_l
	

	$wheel_right.scale = Vector3(-1/radius_wheel_r*0.2+1, radius_wheel_r, radius_wheel_r)
	$wheel_right.position = position_wheel_r
	#$wheel_right.rotation = orientation_wheel_r
	$wheel_right.visible = visibled_wheel_r
	
	$wheel_right/angle_contact_right.visible = visibled_angle_contact_r
	$wheel_right/handrim_right.visible = visibled_handrim_r

func window_user():

	window = Window.new()
	window.title = "Nouvelle fenêtre"
	window.size = Vector2i(350, 650)
	window.position = Vector2i(10, 50)
	window.always_on_top = true
	window.borderless = false
	window.unresizable = false
	var scene = load("res://overlays/biofeedback_optitrack_gui.tscn").instantiate()
	window.add_child(scene)

	get_tree().root.add_child(window)

func _exit_tree():
	window.queue_free()
	
