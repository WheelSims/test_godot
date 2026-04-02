extends Node3D

# Selected phase of the contact angle (start or end)
@export_enum("start", "end") var phase: String

func _process(_delta: float) -> void:
	# Set angular position based on selected phase
	self.rotation_degrees = Vector3(-Config.get_value("overlays.contact_" + phase + "_angle"), 0, 0)
