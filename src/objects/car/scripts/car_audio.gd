class_name CarAudio
extends AudioStreamPlayer3D


func update_audio(current_speed: float, max_speed: float) -> void:
	pitch_scale = lerpf(1, 1.5, current_speed / max_speed)
