extends Node2D

const N_POINTS := 100

@onready var multimesh_instance : MultiMeshInstance2D = %MultiMeshInstance2D

var f_tot_curve : Array[float] = []

func _ready() -> void:
	# Set initial curve to 0
	for i in N_POINTS:
		f_tot_curve.append(0.0)
	multimesh_instance.multimesh.instance_count = N_POINTS
	
	if Globals.main.has_node("PythonBridge"):
		Globals.main.get_node("PythonBridge").send("biofeedback_pushrim_kinetics_connect", {"ip": "dummy"}, "once")
		Globals.main.get_node("PythonBridge").send("biofeedback_pushrim_kinetics_process", {}, "start")

func _process(_delta):
	
	# Check if received something
	if Globals.main.has_node("PythonBridge"):
		var result = Globals.main.get_node("PythonBridge").receive("biofeedback_pushrim_kinetics")
		if result != {} and result["command"] == "biofeedback_pushrim_kinetics_process":
			for i in N_POINTS:
				f_tot_curve[i] = result["data"]["FtotCurve"][i]
			
	# Update the multimesh
	for i in N_POINTS:
		multimesh_instance.multimesh.set_instance_transform_2d(i, 
		Transform2D(0.0, Vector2(i, -f_tot_curve[i])))
		multimesh_instance.multimesh.set_instance_color(i, Color(1,0,0))
