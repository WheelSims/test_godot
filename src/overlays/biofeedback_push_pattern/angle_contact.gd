extends Node3D

# ---------------------------------------------------------------------- #
# Visualization of contact angle phase (start or end)
# - rotates the node based on the selected phase angle from config
# ---------------------------------------------------------------------- #

# Selected phase of the contact angle (start or end)
@export_enum("start", "end") var phase: String


func _process(_delta: float) -> void:
	# Set angular position based on selected phase
	self.rotation_degrees = Vector3(-Config.get_value("overlays.contact_angle_" + phase), 0, 0)
