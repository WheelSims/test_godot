extends PathFollow3D

@export var speed : float = 5.0  # Unité 3D par seconde

func _process(delta):
	progress += speed * delta
