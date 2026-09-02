extends Node2D

const N_POINTS := 100

@onready var n_answers := 0
@onready var multimesh_instance : MultiMeshInstance2D = %MultiMeshInstance2D

var f_tot_curve : Array[float] = []

func _ready() -> void:
	# Set initial curve to 0	
	for i in N_POINTS:
		f_tot_curve.append(0.0)
	multimesh_instance.multimesh.instance_count = N_POINTS
	await SignalBus.python_connected
	await Globals.main.get_node("PythonBridge").run(
			"biofeedback_pushrim_kinetics_connect", [], {"ip": "dummy"}
		)
	update_loop()


func update_loop() -> void:
	while true:
		var result = await Globals.main.get_node("PythonBridge").run(
			"biofeedback_pushrim_kinetics_process", [], {}
		)
		for i in N_POINTS:
			f_tot_curve[i] = result["FtotCurve"][i]
				
		# Update the multimesh
		for i in N_POINTS:
			multimesh_instance.multimesh.set_instance_transform_2d(i, 
			Transform2D(0.0, Vector2(i, -f_tot_curve[i])))
			multimesh_instance.multimesh.set_instance_color(i, Color(1,0,0))
